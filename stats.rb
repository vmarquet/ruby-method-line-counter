#!/usr/bin/env ruby


require 'pp'
require 'ripper'


def blue(s); "\033[34m#{s}\033[0m"; end
def green(s); "\033[32m#{s}\033[0m"; end
def yellow(s); "\033[33m#{s}\033[0m"; end
def red(s); "\033[31m#{s}\033[0m"; end


# Return an array of line numbers.
def find_line_numbers array
  line_numbers = []
  array.each do |item|
    if item.is_a? Array
      if item.size == 2 && item[0].is_a?(Integer) && item[1].is_a?(Integer)
        line_numbers << item[0]
      else
        lineno = find_line_numbers item
        line_numbers << lineno
        line_numbers = line_numbers.flatten.uniq
      end
    end
  end
  return line_numbers
end



if ARGV[0] == nil
  puts 'Please specify the glob patterns to select files.'
  puts "Example:\n$ #{$0} 'app/models/*.rb'"
  abort
end



def analyse path
  code = File.open path
  sexp = Ripper.sexp code
  commands = sexp[1]  # where sexp[0] = :program

  puts "Analysing #{path}..."

  classes = commands.select{ |c| c[0] == :class }

  classes.each do |klass|
    puts "Found class #{blue klass[1][1][1]}"

    bodystmt = klass.find{ |item| item.is_a?(Array) && item[0] == :bodystmt }
    commands = bodystmt[1]

    defs = commands.select{ |c| c[0] == :def }
    puts "Found #{defs.size} methods"

    stats = []

    defs.each do |def_|
      ident = def_.find{ |d| d.is_a?(Array) && d[0] == :@ident }
      func_name = ident[1]

      bodystmt = def_.find{ |d| d.is_a?(Array) && d[0] == :bodystmt }
      commands = bodystmt[1]

      line_numbers = find_line_numbers commands
      next if line_numbers.size == 0

      line_count = line_numbers.max - line_numbers.min + 1
      stats << {ident: func_name, line_count: line_count}
    end

    stats.sort_by!{ |item| item[:line_count] }.reverse!

    stats.each do |stat|
      if stat[:line_count] <= 15
        print green('✔')
      elsif stat[:line_count] <= 30
        print yellow('✔')
      else
        print red('✘')
      end

      print " " + stat[:line_count].to_s.rjust(3, ' ') + " "
      puts stat[:ident]
    end
  end
end



Dir.glob(ARGV[0]).each do |path|
  analyse path
  puts "\n"
end



