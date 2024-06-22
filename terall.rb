require 'optparse'
require 'json'

known_programs = {}
optionParser = OptionParser.new

def addExisitingPrgrms
  lines = ''
  unless File.zero?('program_data.json')
    File.open('program_data.json', 'r') do |f|
      JSON.parse(f.read)['programs'].each do |program|
        lines += <<~JSON
          ,{
            "name": "#{program['name']}",
            "executable": "#{String.new(program['executable']).gsub('\\', '\\\\\\\\')}"
          }
        JSON
      end
    end
  end
  lines
end

def createJSON(known_programs)
  json_pattern = '{"programs": ['
  known_programs.keys.each do |programName|
    json_pattern += <<~JSON
      {
        "name": "#{programName}",
        "executable": "#{known_programs[programName]}"
      }
    JSON
  end

  # If the previous file contains data, it will be added to the current file
  json_pattern += "\n#{addExisitingPrgrms}"
  json_pattern += ']}'

  File.open('program_data.json', 'w') do |f|
    f.write(json_pattern)
  end
end

def addProgramFlag(optionParser)
  json = ''
  return if File.zero?('program_data.json')

  File.open('program_data.json', 'r') do |f|
    _json = JSON.parse(f.read)
    json = _json
  end

  # For each program, it generates a short and a long flag
  (json['programs']).each do |i|
    short_flag = String.new(i['name']).downcase.chars.at(0)
    long_flag = String.new(i['name']).downcase.gsub('.exe', '')
    exe_path = i['executable']

    optionParser.new do |opt|
      opt.on("-#{short_flag}", "--#{long_flag}", "Open #{long_flag}") do
        cmd = "\"#{exe_path}\""
        system(cmd)
      end
    end
  end
end

def addNewProgram(known_programs)
  print 'Path to executable: '
  url = gets.chomp

  # Remove "" from the path
  url = url.strip.tr('"', '')
  url = url.gsub('\\', '\\\\\\\\')

  program_name = url.split('\\')[-1]
  program_name.split('.')[-1]
  known_programs[program_name] = url
  createJSON(known_programs)
end

# Read and parse JSON children to program arguments
File.open('program_data.json', 'w') unless File.exist?('program_data.json')
addProgramFlag(optionParser)

optionParser.new do |opts|
  opts.on('-a', '--add', 'Add a new program') do
    addNewProgram(known_programs)
  end
end.parse!