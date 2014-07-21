class Float
  def near?(other, relative_epsilon=EPSILON, epsilon=EPSILON)
    diff = (self - other).abs
    if other == self || diff < epsilon
      true
    else
      # relative error
      (diff / (self > other ? self : other)).abs < relative_epsilon
    end
  end
end

class Integer
  def near?(other, _)
    self == other
  end
end
