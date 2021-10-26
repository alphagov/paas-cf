# See billing_scenarios_eu_west_1.ods for details

Feature: Test AWS RDS bills calculated correctly

  Background:
  Given a clean billing database
  # (This is run before each scenario, including those in scenario outline.)

  Scenario: Test initial RDS bill
  -------------------------------

  Given a tenant has a postgres small-10.5 between '2020-01-05 00:00:00' and '2020-06-05 11:00'
  When billing is run for Jun 2020
  Then the bill, including VAT, should be £4.36

####

  Scenario Outline: Test Postgres RDS bill
  ----------------------------------------

  Given a tenant has a <postgres database> between '<start date>' and '<end date>'
  When billing is run for <month and year>
  Then the bill, including VAT, should be £<bill>

  Examples:
    | postgres database | start date | end date | month and year | bill |
    | postgres small-11 | 2021-05-01 | 2021-06-01 | May 2021 | 40.05 |


####

  Scenario: Test bill during the month RDS is upgraded
  ----------------------------------------------------

  Given a tenant has a postgres xlarge-ha-9.5 between '2018-11-01 00:00:00' and '2020-06-07 00:59'
  And the tenant has a postgres xlarge-ha-10.5 between '2020-06-07 00:59' and '2020-06-07 01:59'
  And the tenant has a postgres xlarge-ha-11 high-iops between '2020-06-07 01:59' and '2020-12-01'

  When billing is run for Jun 2020

  Then the bill, including VAT, should be £4208.24


####



  Scenario: Test bill during the month RDS instance is renamed
  ------------------------------------------------------------

  Given a tenant has a postgres xlarge-ha-11 between '2018-11-01 00:00' and '2020-06-07 00:59'
  And the tenant has a postgres xlarge-ha-11 between '2020-06-07 00:59' and '2020-06-07 01:59'

  When billing is run for Jun 2020

  Then the bill, including VAT, should be £539.38
