require 'minitest/autorun'
require 'timeout'

# Class responsible for returning the CS id that serves the most customers
# @param customer_success [Array<Integer>] customer success experience level
# @param customers [Array<Integer>] customers experience level
# @param away_customer_success [Array<Integer>] unavailable customer success ids
# @return [Integer] customer_success id
class CustomerSuccessBalancing
  attr_reader :customer_success, :customers, :away_customer_success

  def initialize(customer_success, customers, away_customer_success)
    @customer_success = customer_success
    @customers = customers
    @away_customer_success = away_customer_success
  end

  # Returns the ID of the customer success with most customers
  def execute
    # Remove all away CS's
    available_customer_success = customer_success.reject { |item| away_customer_success.include?(item[:id]) }

    # Sort all CS's by score
    available_customer_success.sort_by! { |item| item[:score] }

    # Sort all CS's by score
    customers.sort_by! { |item| item[:score] }

    matched_customers = {}

    available_customer_success.each do |available_cs|
      score = available_cs[:score]

      users_count = (customers.dup - customers.delete_if { |customer| customer[:score] <= score }).count

      matched_customers[available_cs[:id]] = users_count
    end

    id, max_value = matched_customers.max_by { |_, value| value }
    count_of_max_value = matched_customers.count { |_, value| value == max_value }

    count_of_max_value > 1 ? 0 : id
  end

  private

  def maximum_away_customer_success_size = (customer_success.size / 2).floor

  def valid_away_customer_success_size?
    maximum_away_customer_success_size <= away_customer_success.size || away_customer_success.empty?
  end
end

# Class responsible for executing the test suite
class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    balancer = CustomerSuccessBalancing.new(
      build_scores([11, 21, 31, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..999)),
      build_scores(Array.new(10_000, 998)),
      [999]
    )
    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 998, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(
      build_scores([1, 2, 3, 4, 5, 6]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 2, 3, 6, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [1, 3, 2]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [4, 5, 6]
    )
    assert_equal 3, balancer.execute
  end

  def test_scenario_eight
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 40, 95, 75]),
      build_scores([90, 70, 20, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: }
    end
  end
end
