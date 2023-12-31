require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_phone_number(phone_number)
  only_number = phone_number.gsub(/\D/, "")

  if only_number.size == 10
    only_number
  elsif only_number.size == 11 && only_number[0] == 1
    only_number[1..10]
  else
    "bad number"
  end
end

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

best_hours_arr = []

def get_best_hours(date)
  hour_and_minutes = date.split[1]
  hour = hour_and_minutes.split(':')[0]
  best_hours_arr.push(hour)
end

def get_best_days(date)

end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless  Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

best_hours_arr = []
best_days_arr = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  full_date_arr = row[:regdate].split

  day =  Date.strptime(full_date_arr[0], '%m/%d/%Y')
  best_days_arr.push(day.wday)

  hour = full_date_arr[1].split(':')
  best_hours_arr.push(hour[0])

  zipcode = clean_zipcode(row[:zipcode])
  phone = clean_phone_number(row[:homephone])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

end

best_hours_hash = best_hours_arr.reduce(Hash.new(0)) do |result, hour|
  result[hour] += 1
  result
end

best_days_hash = best_days_arr.reduce(Hash.new(0))  do |result, day|
  result[day] += 1
  result
end

best_hour = best_hours_hash.max_by{ |k,v| v}

best_day = best_days_hash.max_by{ |k,v| v }

best_day_name = Date::DAYNAMES[best_day[0].to_i]

puts "best day is #{best_day_name}"
puts "best hour is #{best_hour[0]}"
