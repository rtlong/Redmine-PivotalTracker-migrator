

class Numeric
  def round_to_array(array)
    array = array.unshift(0).sort.uniq
    r = 0
    array.each do |i|
      r = i if self >= i
    end
    return r
  end
end