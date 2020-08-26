require "rubocop"

module RuboCop
  module Cop
    module CustomCops
      class MustCaptureXStr < Cop
        MSG = "Must capture execution string output".freeze

        def on_xstr(node)
          return if node.heredoc?

          add_offense(node) unless node&.parent&.type == :lvasgn
        end
      end

      class MustCheckXStrExitstatus < Cop
        MSG = "After using execution string must check exitstatus".freeze

        CHECKS = [
          s(:send, s(:gvar, :$CHILD_STATUS), :success?),
          s(:send, s(:gvar, :$CHILD_STATUS), :exitstatus),
          s(:send, s(:gvar, :$?), :success?),
          s(:send, s(:gvar, :$?), :exitstatus),
        ].freeze

        def on_xstr(node)
          return if node.heredoc?

          scope = node
          loop do
            break if scope.nil?
            break if scope.type == :begin

            scope = scope.parent
          end
          children = scope&.children || []

          # Reject anything before the current node
          followers = children.drop_while do |child_node|
            child_node.loc.last_line <= node.loc.last_line
          end

          return add_offense(node) if followers.empty?

          follower_children = followers.first.each_descendant(&:children).to_a
          check_present = follower_children.any? { |c| CHECKS.include? c }

          add_offense(node) unless check_present
        end
      end
    end
  end
end
