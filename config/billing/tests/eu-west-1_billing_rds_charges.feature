Feature: Test AWS RDS bills calculated correctly

  Background:
  Given a clean billing database
  # (This is run before each scenario, including those in scenario outline.)

  Scenario: Test initial RDS bill
  -------------------------------

  Given a tenant has a postgres small-10.5 between '2020-01-05 00:00:00' and '2020-06-05 11:00'
  When billing is run for Jun 2020
  Then the bill, including VAT, should be £6.44

####

  Scenario Outline: Test Postgres RDS bill
  ----------------------------------------

  Given a tenant has a <postgres database> between '<start date>' and '<end date>'
  When billing is run for <month and year>
  Then the bill, including VAT, should be £<bill>

  Examples:
    | postgres database | start date | end date | month and year | bill |
    | postgres small-11 | 2021-05-01 | 2021-06-01 | May 2021 | 40.05 |

# Calculation from https://calculator.aws/#/createCalculator/RDSPostgreSQL:
# 1 instance(s) x 0.039 USD hourly x 744 hours in a month = 29.016 USD
# 100 GB per month x  0.127 USD x 1 instances = 12.70 USD (Storage Cost)
# Total cost in GBP, excluding VAT = 0.8*(12.70 + 29.016) = £33.3728
# Total cost in GBP, including VAT = (0.8*(12.70 + 29.016))*1.2 = £40.05
# These charges exclude VAT
# postgres small-11 has storage_in_mb = 100GB and is an AWS RDS db.t3.small (from service_plans table)
# Note that "postgres small-11" is listed because this is the entry that appears in the pricing_plans table. The entry that appears in service_plans is "small-11".

####

  Scenario: Test bill during the month RDS is upgraded
  ----------------------------------------------------

  Given a tenant has a postgres xlarge-ha-9.5 between '2018-11-01 00:00:00' and '2020-06-07 00:59'
  And the tenant has a postgres xlarge-ha-10.5 between '2020-06-07 00:59' and '2020-06-07 01:59'
  And the tenant has a postgres xlarge-ha-11 high-iops between '2020-06-07 01:59' and '2020-12-01'

  When billing is run for Jun 2020

  Then the bill, including VAT, should be £5673.71

  # Calculation for the above:
  # Note that $3.224 is the price per hour but bills are calculated to the second
  #
  #Calculation
  # ((3.224*521940/3600)) +  ((3.224)) + ((3.152*2066460/3600))) + ((2 * ((0.253*(2097152/1024))) + (0.253*(10485760/1024))))) * 0.8 * 1.2 gives 5761.87717999761796733887
# Calculated cost in USD between '2018-11-01 00:00:00' and '2020-06-07 00:59' (instance followed by storage) is ((521940)*(3.224/3600)) + ((0.253*(2097152/1024)))) = 568.39702509
# Calculated cost in USD between '2020-06-07 00:59' and '2020-06-07 01:59' (instance followed by storage) is  ((3600)*(3.224/3600)) + ((3600/2678401)*((0.253*(2097152/1024)))) = 3.920430108
# Check the storage cost formula (https://aws.amazon.com/rds/postgresql/pricing/) - need multi-AZ charge ($0.253) because HA
# Calculated cost in USD between '2020-06-07 01:59' and '2020-07-01 00:00' (instance followed by storage) is ((2066460)*(3.152/3600)) + ((2066460/2678401)*((0.253*(10485760/1024)))) = 3808.112977778
# Total cost in GBP, excluding VAT = 0.8*(568.39702509 + 3.920430108 + 3808.112977778) = £3504.344346381
# Total cost in GBP, including VAT = (0.8*(568.39702509 + 3.920430108 + 3808.112977778))*1.2 = £4205.21321565696
# Note: the AWS charges exclude VAT
# References for calculation: see comparison chart above. Also https://aws.amazon.com/rds/previous-generation/ and https://aws.amazon.com/rds/postgresql/pricing/
# You can get the number of seconds between two dates easily using `select extract(epoch from ('2020-06-07 00:59:00'::timestamp - '2020-01-01 00:00:00'::timestamp));`

####

# For later on, so we can test the full data flow from events -> billing figures.

#  Scenario: Test addition of events
#  Given Add events
#    | event_guid | resource_guid | resource_name | resource_type | org_guid | org_name | space_guid | space_name | duration | plan_guid | plan_name | service_guid | service_name | number_of_nodes | memory_in_mb | storage_in_mb |
#    | 11111111-2222-3333-4444-555555555555 | aaaaaaaa-3333-4444-5555-888888888888 | notify-delivery-worker-priority-rollback | app           | aaaaaaaa-bbbb-1111-2222-333333333333 | govuk-notify | aaaaaaaa-0000-4444-5555-444444444444 | preview    | ["2017-09-07 18:00:47+00","2017-09-08 11:05:01+00") | 00000000-1111-2222-3333-444444444444 | app       | aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee | app          |               1 |         1024 |             0 |
#  When load events into billing database
#  Then a tenant should have a small-10.5 with a valid_from of '2017-09-07 18:00:47+00'


  Scenario: Test bill during the month RDS has a change
  ----------------------------------------------------

  Given a tenant has a postgres xlarge-ha-11 between '2018-11-01 00:00' and '2020-06-07 00:59'
  And the tenant has a postgres xlarge-ha-11 between '2020-06-07 00:59' and '2020-06-07 01:59'

  When billing is run for Jun 2020

  Then the bill, including VAT, should be £1436.62

#  Start	Stop	Total seconds	Storage in MB	Compute per hour	Storage per month	Compute cost per second	Compute cost USD	Comnpute cost GBP ex VAT	Compute cost GBP incl VAT	Storage cost USD	Storage cost GBP ex VAT	Storage cost GBP incl VAT	Total GBP incl VAT
# 01/06/2020 00:00:00	07/06/2020 00:59:00	521940	2097152	3.152	0.253	0.0008755555556	457.04	365.632	438.7584	518.144	414.5152	497.41824	936.17664
# 2020-06-07 00:59	2020-06-07 01:59	3600	2097152	3.152	0.253	0.0008755555556	3.152	2.5216	3.02592	518.144	414.5152	497.41824	500.44416
