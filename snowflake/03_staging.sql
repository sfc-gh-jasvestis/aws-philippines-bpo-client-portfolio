-- Validate the producer contract before building downstream objects.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

EXECUTE IMMEDIATE $$
DECLARE
  violations INTEGER;
  invalid_source EXCEPTION (-20001, 'Synthetic source failed grain or measure validation');
BEGIN
  SELECT COUNT(*) INTO :violations FROM (
    SELECT ENTITY_ID, EVENT_DATE
    FROM RAW.ACCOUNT_DAILY
    GROUP BY ENTITY_ID, EVENT_DATE HAVING COUNT(*) <> 1
    UNION ALL
    SELECT observation.ENTITY_ID, observation.EVENT_DATE
    FROM RAW.ACCOUNT_DAILY observation
    LEFT JOIN RAW.ACCOUNTS account ON account.ID = observation.ENTITY_ID
    WHERE account.ID IS NULL OR observation.CONTACT_COUNT < 0
       OR observation.REVENUE_PHP < 0
       OR observation.BREACH_COUNT < 0 OR observation.BREACH_COUNT > observation.ESCALATION_COUNT
       OR observation.ESCALATION_COUNT > observation.CONTACT_COUNT
       OR observation.SERVICE_CREDIT > observation.BREACH_COUNT
       OR observation.QA_AUDIT_DONE > observation.QA_AUDIT_DUE
  );
  IF (violations > 0) THEN
    RAISE invalid_source;
  END IF;
END;
$$;
