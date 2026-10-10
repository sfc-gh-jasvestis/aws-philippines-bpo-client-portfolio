import { NextResponse } from 'next/server';
import { executeQuery } from '@/lib/snowflake';
import { demoPlatform } from '@/lib/platform';

export const dynamic = 'force-dynamic';

// Only these fixed, read-only queries can run. The model never writes SQL; it
// only summarises rows returned here, so every answer is traceable to data.
const INTENTS: Record<string, { match: RegExp; sql: string }> = {
  accounts: {
    match: /breach|account|client|city|site|worst|highest|credit/i,
    sql: `SELECT ENTITY_ID, ENTITY_NAME, REGION, CATEGORY, ESCALATION_COUNT, BREACH_COUNT, SERVICE_CREDIT_COUNT, ROUND(ESCALATION_BREACH_PCT, 1) AS ESCALATION_BREACH_PCT
FROM CURATED.PERFORMANCE_SUMMARY
QUALIFY DENSE_RANK() OVER (ORDER BY BREACH_COUNT DESC) <= 3
ORDER BY BREACH_COUNT DESC, ESCALATION_COUNT DESC`,
  },
  types: {
    match: /type|reason|cause|why|escalation|complaint/i,
    sql: `SELECT ESCALATION_TYPE, ESCALATION_COUNT, BREACH_COUNT, SERVICE_CREDIT_COUNT, ROUND(ESCALATION_BREACH_PCT, 1) AS ESCALATION_BREACH_PCT
FROM CURATED.ESCALATION_SUMMARY ORDER BY BREACH_COUNT DESC LIMIT 8`,
  },
  kpis: {
    match: /.*/,
    sql: `SELECT TITLE, DISPLAY, SOURCE_WATERMARK FROM CURATED.KPI_SUMMARY ORDER BY SORT_ORDER`,
  },
};

const DEFINITIONS =
  'Contacts without escalation = contacts with no escalation / contacts handled. Escalation breach rate = SLA breaches / escalations raised. ' +
  'A service credit is a contractual credit owed to the client after an SLA breach. Site connectivity outage escalations are site-wide and are always closed within SLA. ' +
  'Values are in PHP; accounts are served from delivery sites in 5 Philippine cities. All data is synthetic demo data.';

// provider 'cortex' = Snowflake AI_COMPLETE; 'bedrock' = Amazon Bedrock Claude
// via the external-access UDF APP.BEDROCK_GENERATE (aws/setup_aws.py).
async function summarise(question: string, rows: unknown[], provider: 'cortex' | 'bedrock' = 'cortex'): Promise<string> {
  const prompt =
    'You are a client portfolio analyst at a Philippine BPO provider. Answer ONLY from the JSON rows and definitions below. ' +
    'If the rows do not answer the question, say so. Do not invent numbers. Keep it under 120 words.\n' +
    `Definitions: ${DEFINITIONS}\nRows: ${JSON.stringify(rows)}\nQuestion: ${question}`;
  const out = await executeQuery<{ R: string }>(
    provider === 'bedrock' ? 'SELECT APP.BEDROCK_GENERATE(?) AS R' : `SELECT AI_COMPLETE('claude-sonnet-4-5', ?) AS R`,
    [prompt],
  );
  const raw = String(out[0]?.R ?? '').trim();
  // AI_COMPLETE returns a JSON string literal; decode it when present.
  try {
    const parsed = JSON.parse(raw);
    return typeof parsed === 'string' ? parsed : raw;
  } catch {
    return raw;
  }
}

export async function POST(req: Request) {
  let body: any;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 });
  }
  const question = typeof body?.question === 'string' ? body.question.trim().slice(0, 2000) : '';
  const memo = body?.mode === 'memo';
  if (!memo && !question) return NextResponse.json({ error: 'Question required' }, { status: 400 });

  try {
    if (memo) {
      const provider = demoPlatform() === 'aws' ? 'bedrock' : 'cortex';
      const [kpis, accounts, types, risk, bands] = await Promise.all([
        executeQuery(INTENTS.kpis.sql),
        executeQuery(INTENTS.accounts.sql),
        executeQuery(INTENTS.types.sql),
        executeQuery(`SELECT ENTITY_ID, ROUND(BREACH_PROB_7D, 2) AS BREACH_PROB_7D, RISK_BAND
FROM ML.BREACH_RISK_SCORES ORDER BY BREACH_PROB_7D DESC LIMIT 5`),
        executeQuery(`SELECT RISK_BAND, COUNT(*) AS ACCOUNTS FROM ML.BREACH_RISK_SCORES GROUP BY RISK_BAND`),
      ]);
      const rows = { kpis, topBreachAccounts: accounts, escalationTypes: types, top5ByRisk: risk, accountsPerRiskBand: bands };
      const answer = await summarise(
        'Draft a short action memo for the Head of Client Portfolio Delivery with 3 prioritised actions, citing the figures.',
        [rows],
        provider,
      );
      return NextResponse.json({ answer, sources: rows, provider: provider === 'bedrock' ? 'Amazon Bedrock (Claude Sonnet 4.5)' : 'Snowflake Cortex AI_COMPLETE (claude-sonnet-4-5)', draft: true, synthetic: true });
    }
    const key = Object.keys(INTENTS).find((k) => INTENTS[k].match.test(question))!;
    const rows = await executeQuery(INTENTS[key].sql);
    const answer = await summarise(question, rows);
    return NextResponse.json({ answer, sql: INTENTS[key].sql, sources: rows, synthetic: true });
  } catch (err) {
    console.error('ask route failed', err);
    return NextResponse.json({ error: 'AI service unavailable' }, { status: 503 });
  }
}
