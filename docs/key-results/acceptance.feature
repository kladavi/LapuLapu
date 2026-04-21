Feature: OKR Key Results Management
  As a project manager
  I want to define and track Key Results linked to Objectives
  So that I can measure progress toward strategic goals

  Background:
    Given the LapuLapu PM dashboard is loaded with project data
    And objectives O1 through O6 and Tier-2 objectives exist

  # ── Lifecycle ──

  Scenario: Create a numeric Key Result
    Given I am on the Key Results tab
    When I click "New Key Result"
    And I fill in:
      | Field        | Value                          |
      | Title        | Reduce P1 MTTR                 |
      | Objective    | H-3                            |
      | Metric Type  | Numeric                        |
      | Start Value  | 4.2                            |
      | Target Value | 2.5                            |
      | Target Date  | 2026-06-30                     |
      | Description  | Track P1 incident resolution   |
    And I click "Save"
    Then a new KR with ID "KR001" appears in the list
    And its status is "Not Started"
    And its progress is 0%

  Scenario: Create a boolean Key Result
    Given I am on the Key Results tab
    When I click "New Key Result"
    And I set Metric Type to "Boolean"
    And I fill in Title "Launch predictive monitoring"
    And I select Objective "H-3"
    And I set Target Date to "2026-09-30"
    And I click "Save"
    Then the KR shows progress 0% (Not complete)
    And Start Value is 0 and Target Value is 1

  Scenario: Edit a Key Result definition
    Given KR001 exists with title "Reduce P1 MTTR"
    When I open KR001 detail view
    And I click "Edit"
    And I change Target Value to "2.0"
    And I click "Save"
    Then KR001 Target Value is 2.0
    And the Change Log contains "Target Value changed from 2.5 to 2.0"

  Scenario: View Key Result detail
    Given KR001 exists
    When I click on KR001 in the list
    Then I see the detail panel with all fields
    And I see the Progress Log table
    And I see the Change Log table

  # ── Progress Tracking ──

  Scenario: Add a progress entry
    Given KR001 exists with Start Value 4.2 and Target Value 2.5
    When I open KR001 detail view
    And I click "Add Progress"
    And I enter Value "3.1" and Comment "Improved correlation rules"
    And I click "Save Entry"
    Then the Progress Log shows a new row with today's date
    And Current Value updates to 3.1
    And progress computes to approximately 65%

  Scenario: Progress percentage clamped to 0-100
    Given KR002 exists with Start 0, Target 100, Current 120
    Then the displayed progress is 100%

  Scenario: Boolean KR progress
    Given KR003 is boolean with Current Value 0
    Then progress is 0%
    When Current Value is updated to 1
    Then progress is 100%

  # ── Objective Linkage ──

  Scenario: Objective with no Key Results shows warning
    Given objective B-7 has no linked Key Results
    When I view the Key Results tab
    Then B-7 shows a "No KRs" warning badge in the objective filter

  Scenario: Objective with >5 Key Results shows warning
    Given objective H-3 has 6 linked Key Results
    When I view H-3's Key Results
    Then a warning appears: "Consider decomposing — 6 KRs linked"

  # ── Filtering & Search ──

  Scenario: Filter by objective
    Given KR001 is linked to H-3 and KR002 is linked to B-1
    When I select objective filter "H-3"
    Then only KR001 appears in the list

  Scenario: Filter by status
    Given KR001 has status "On Track" and KR002 has status "Behind"
    When I select status filter "Behind"
    Then only KR002 appears

  Scenario: Search by title
    Given KR001 has title "Reduce P1 MTTR"
    When I type "MTTR" in the search box
    Then KR001 appears and other KRs are hidden

  # ── Dashboard Integration ──

  Scenario: Dashboard shows Key Results summary
    Given 3 Key Results exist (1 On Track, 1 Behind, 1 Complete)
    When I view the Dashboard tab
    Then the Key Results card shows "3" total
    And clicking it navigates to the Key Results tab

  # ── Objective Detail Integration ──

  Scenario: Objective detail shows linked KRs
    Given KR001 and KR004 are linked to H-3
    When I select H-3 in the Objectives tab
    Then the detail panel includes a "Key Results" section
    And it lists KR001 and KR004 with progress bars
