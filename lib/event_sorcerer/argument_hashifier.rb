module EventSorcerer
  # Public: Helper to hashify a method call.
  module ArgumentHashifier
    # Public: Creates a Hash representing a particular method call.
    #
    # parameters - an Array of the parameters for a method.
    # arguments  - an Array of the arguments for a particular method call.
    #
    # Returns a Hash where arguments are keyed by the corrosponding parameter
    # name.
    def self.hashify(parameters, arguments)
      {}.tap do |hash|
        required_positionals(parameters).each do |param|
          hash[param] = arguments.shift
        end

        keyword_arguments = arguments.last.is_a?(Hash) ? arguments.pop : {}
        hash.merge! keyword_arguments
      end
    end

    private

    # Private: Returns an Array of the required positional parameter names for
    #          a given set of parameters.
    def self.required_positionals(parameters)
      parameters.select { |type, _| type == :req }.map(&:last)
    end
  end
end
