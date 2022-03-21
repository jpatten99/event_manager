require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phonenumber(phonenumber)
  if phonenumber.nil?
    '0000000000'
  elsif phonenumber.length<10
    num_of_zeros = 10 - phonenumber.length
    phonenumber.rjust(num_of_zeros, '0')
  elsif phonenumber.length == 11 && phonenumber[o] == '1'
    phonenumber[1..-1]
  elsif phonenumber.length == 11 && phonenumber[0] != '1'
    '0000000000'
  else 
    phonenumber
  end
end

=begin    tried making function but keeps returning empty hash :'(
code is only like 4 lines anyway

def find_peak_hours(inputArray)
  peak_hours = Hash.new(0)
  inputArray.each do |row|
  time = row[:regdate]
  time = Time.strptime(time, "%m/%d/%y %k:%M").hour
  peak_hours[time] += 1
  end
  p peak_hours
end
=end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

peak_hours = Hash.new(0)
peak_days_of_week = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])

  time = row[:regdate]
  time = Time.strptime(time, "%m/%d/%y %k:%M").hour
  peak_hours[time] += 1

  date = row[:regdate]
  year = Date.strptime(date, "%m/%d/%y %k:%M").year
  month = Date.strptime(date, "%m/%d/%y %k:%M").month
  day = Date.strptime(date, "%m/%d/%y %k:%M").day
  day_of_week = Date.new(year,month,day).wday
  peak_days_of_week[day_of_week] += 1  

  #p "#{year} #{month} #{day}"

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  #save_thank_you_letter(id,form_letter)
end

#find_peak_hours(contents)
puts "hash of peak hours"
p peak_hours
puts
puts "hash of peak days of week 0: Sun 1: Mon... 6: Sat"
p peak_days_of_week