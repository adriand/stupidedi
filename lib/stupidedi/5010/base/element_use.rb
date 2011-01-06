module Stupidedi
  module FiftyTen
    module Base

      #
      # Abstract parent of SimpleElementUse and ComponentElementUse
      #
      class ElementUse
        attr_reader :element_def

        attr_reader :requirement_designator

        def initialize(element_def, requirement_designator)
          @element_def, @requirement_designator = element_def, requirement_designator

          unless element_def.is_a?(ElementDef)
            raise TypeError, "First argument must be a kind of ElementDef"
          end

          unless requirement_designator.is_a?(Designations::ElementRequirement)
            raise TypeError, "Second argument must be a kind of ElementRequirement"
          end
        end

        def required?
          @requirement_designator.required?
        end
      end

      #
      # Describes the use of a simple or composite element when the parent structure is a
      # SegmentDef. In this case, it has a repetition count. Compare to ComponentElementUse.
      #
      class SimpleElementUse < ElementUse
        attr_reader :repetition_count

        def initialize(element_def, requirement_designator, repetition_count)
          super(element_def, requirement_designator)
          @repetition_count = repetition_count

          unless @repetition_count.is_a?(Designations::ElementRepetition)
            raise TypeError, "Third argument must be a kind of ElementRepetition"
          end
        end
      end

      #
      # Describes the use of a simple element when the parent structure is a CompositeElementDef,
      # in which case, it is not allowed to repeat.
      #
      class ComponentElementUse < ElementUse
      end

    end
  end
end
