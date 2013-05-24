class PQueue
  def pop_while
    a = []
    return a unless block_given?

    while !@que.empty? && yield(@que.top) do
      a << @que.pop
    end

    a
  end

  def delete(obj)
    @que.delete(obj)
  end
end
