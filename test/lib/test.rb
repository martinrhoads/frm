# this is the place to put common testing code

def compare_line_by_line(chunk1,chunk2)
  arr1=chunk1.split("\n")
  arr2=chunk2.split("\n")
  arr1.each_with_index do |line,i|
    unless line == arr2[i]
      puts "line number #{i} is different:"
      puts "  #{line}" 
      puts "  #{arr2[i]}"
    end
  end
end
