module DEVS
  module Parallel
    class CoupledModel < Classic::CoupledModel
      undef :select
    end
  end
end
