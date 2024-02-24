# frozen_string_literal: true

require 'minitest/autorun'
require 'timeout'

# Class responsible for balancing customer success allocation.
#
# This class determines the customer success (CS) ID that serves the most customers
# based on the given data. It also handles scenarios where certain customer success
# agents are unavailable.
#
class CustomerSuccessBalancing
  # Exception raised when the size of away_customer_success is equal to half
  # the size of customer_success.
  class MaximumAwayCustomerSuccessSizeReached < StandardError; end

  # Initializes a new instance of CustomerSuccessBalancing.
  #
  # Raises a MaximumAwayCustomerSuccessSizeReached exception if the away_customer_success
  # array size is equal to half the size of the customer_success array.
  #
  # @param customer_success [Array<Hash>] Array of customer success data including ID and experience level.
  # @param customers [Array<Hash>] Array of customer data including ID and experience level.
  # @param away_customer_success [Array<Integer>] Array of IDs of unavailable customer success agents.
  #
  def initialize(customer_success, customers, away_customer_success)
    unless valid_away_customer_success_maximum_size?(customer_success, away_customer_success)
      raise MaximumAwayCustomerSuccessSizeReached
    end

    @customer_success = customer_success
    @customers = customers
    @away_customer_success = away_customer_success
  end

  # Executes the customer success balancing algorithm.
  #
  # This method calculates the ID of the customer success agent that serves the most customers.
  # If there are multiple customer success agents with the same number of served customers,
  # it returns 0.
  #
  # @return [Integer] ID of the customer success agent with the most customers served,
  #   or 0 if there are multiple customer success agents with the same number of served customers.
  #
  def execute
    customer_success = sort_customer_success
    customers = sort_customers

    cs_customers_count = {}

    customer_success.each do |available_cs|
      score = available_cs[:score]

      original_customers_count = customers.size
      customers.reject! { |customer| customer[:score] <= score }

      cs_customers_count[available_cs[:id]] = (original_customers_count - customers.size)
    end

    fetch_customer_success_id(cs_customers_count)
  end

  private

  def fetch_customer_success_id(cs_customers_count)
    customer_success_id, max_value = cs_customers_count.max_by { |_id, value| value }
    count_of_max_value = cs_customers_count.count { |_id, value| value == max_value }

    count_of_max_value > 1 ? 0 : customer_success_id
  end

  def sort_customer_success
    remove_away_customer_success_ids.sort_by { |customer_success| customer_success[:score] }
  end

  def remove_away_customer_success_ids
    @customer_success.reject { |customer| @away_customer_success.include?(customer[:id]) }
  end

  def sort_customers = @customers.sort_by { |customer| customer[:score] }

  protected

  # Checks if the size of away_customer_success array is less than half the size of customer_success array.
  #
  # @param customer_success [Array<Hash>] Array of customer success data including ID and experience level.
  # @param away_customer_success [Array<Integer>] Array of IDs of unavailable customer success agents.
  # @return [Boolean] True if the size of away_customer_success is less than half the size of customer_success,
  #   otherwise false.
  #
  def valid_away_customer_success_maximum_size?(customer_success, away_customer_success)
    maximum_away_customer_success_size = (customer_success.size / 2).floor

    maximum_away_customer_success_size >= away_customer_success.size
  end
end

# Test class responsible for executing and validating the customer success balancing algorithm
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

  def test_scenario_nine
    exception = CustomerSuccessBalancing::MaximumAwayCustomerSuccessSizeReached

    assert_raises(exception) do
      CustomerSuccessBalancing.new(
        build_scores([1, 2, 3]),
        build_scores([2, 3, 4, 5]),
        [1, 2]
      )
    end
  end

  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: }
    end
  end
end
