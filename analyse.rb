require 'open-uri'
require 'json'

require 'sqlite3'

@db = SQLite3::Database.new "matches.db"

ANALYSIS = {
    "highest_score" => nil,
    "highest_score_minus_penalties" => nil,
    "highest_penalty" => nil,
    "highest_teleop_score" => nil,
    "highest_auto_score" => nil,
    "highest_win_margin" => nil,
    "highest_win_margin_no_card" => nil,
    "highest_high_goals" => nil,
    "highest_low_goals" => nil,
    "highest_total_goals" => nil
}

EVENT_OR_TEAM_LIST=ARGV

def analyse key, row, row_key
    ANALYSIS[key] = row if (ANALYSIS[key].nil? \
                                || (row["blue_#{row_key}"] > ANALYSIS[key]["blue_#{row_key}"] \
                                    && row["blue_#{row_key}"] > ANALYSIS[key]["red_#{row_key}"]) \
                                || (row["red_#{row_key}"] > ANALYSIS[key]["blue_#{row_key}"] \
                                    && row["red_#{row_key}"] > ANALYSIS[key]["red_#{row_key}"]))
end

def includesTeams row
    arr = [row["blue_teams"], row["red_teams"]].map { |x| x.split(" ") }.flatten
    !(arr & EVENT_OR_TEAM_LIST).empty?
end

@db.results_as_hash = true
@db.execute("select * from matches") do |row|
    next unless EVENT_OR_TEAM_LIST.length == 0 || EVENT_OR_TEAM_LIST.include?(row["event"]) || includesTeams(row)
    
    row["blue_minus_penalty"] = row["blue_score"] - row["blue_penalty"]
    row["red_minus_penalty"] = row["red_score"] - row["red_penalty"]
    row["winning_alliance"] = "TIE"
    row["winning_alliance"] = "blue" if row["blue_score"] > row["red_score"]
    row["winning_alliance"] = "red" if row["red_score"] > row["blue_score"]
    
    row["win_margin"] = 0
    row["win_margin"] = row["blue_score"].to_f - row["red_score"] if row["winning_alliance"] == "blue"
    row["win_margin"] = row["red_score"].to_f - row["blue_score"] if row["winning_alliance"] == "red"
    
    row["blue_goals"] = row["blue_high_shots"] + row["blue_low_shots"]
    row["red_goals"] = row["red_high_shots"] + row["red_low_shots"]
    
    analyse("highest_score", row, "score")
    analyse("highest_score_minus_penalties", row, "minus_penalty")
    analyse("highest_penalty", row, "penalty")
    analyse("highest_teleop_score", row, "teleop")
    analyse("highest_auto_score", row, "auto")
    analyse("highest_high_goals", row, "high_shots")
    analyse("highest_low_goals", row, "low_shots")
    analyse("highest_total_goals", row, "goals")
    
    if ANALYSIS["highest_win_margin"].nil? || ANALYSIS["highest_win_margin"]["win_margin"] < row["win_margin"]
        ANALYSIS["highest_win_margin"] = row
    end
    
    if ANALYSIS["highest_win_margin_no_card"].nil? || ANALYSIS["highest_win_margin_no_card"]["win_margin"] < row["win_margin"]
        ANALYSIS["highest_win_margin_no_card"] = row if row["blue_score"] != 0 && row["red_score"] != 0
    end
end

EVENTS = {}
WORDS = {
    "qm" => "Qualifications",
    "qf" => "Quarter Finals",
    "sf" => "Semi Finals",
    "f"  => "Finals"
}

@db.execute("select * from events") do |row|
    EVENTS[row["event"]] = row["name"]
end

def match_to_words match
    word = WORDS[match["comp_level"]]
    include_set = match["comp_level"] != "qm"
    
    ret = "#{word} Match #{match["match_number"]}"
    ret = "#{word} #{match["set_number"]} Match #{match["match_number"]}" if include_set
    ret
end

File.write("analysis.json", JSON.pretty_generate(ANALYSIS))

CACHE = ""

def puts str=""
    CACHE << str
    CACHE << "\n"
end

highest = ANALYSIS["highest_score"]
puts "Highest Score:"
puts "\t#{EVENTS[highest["event"]]}"
puts "\t#{match_to_words(highest)}"
puts "\t\tRed:  #{highest["red_teams"]}\t-- #{highest["red_score"]}"
puts "\t\tBlue: #{highest["blue_teams"]}\t-- #{highest["blue_score"]}"
puts

highest = ANALYSIS["highest_score_minus_penalties"]
puts "Highest Score (Minus Penalty Bonus):"
puts "\t#{EVENTS[highest["event"]]}"
puts "\t#{match_to_words(highest)}"
puts "\t\tRed:  #{highest["red_teams"]}\t-- #{highest["red_minus_penalty"]}"
puts "\t\tBlue: #{highest["blue_teams"]}\t-- #{highest["blue_minus_penalty"]}"
puts

highest = ANALYSIS["highest_penalty"]
puts "Highest Penalty:"
puts "\t#{EVENTS[highest["event"]]}"
puts "\t#{match_to_words(highest)}"
puts "\t\tRed:  #{highest["red_teams"]}\t-- #{highest["blue_penalty"]}"
puts "\t\tBlue: #{highest["blue_teams"]}\t-- #{highest["red_penalty"]}"
puts

highest = ANALYSIS["highest_teleop_score"]
puts "Highest Teleoperated Score:"
puts "\t#{EVENTS[highest["event"]]}"
puts "\t#{match_to_words(highest)}"
puts "\t\tRed:  #{highest["red_teams"]}\t-- #{highest["red_teleop"]}"
puts "\t\tBlue: #{highest["blue_teams"]}\t-- #{highest["blue_teleop"]}"
puts

highest = ANALYSIS["highest_auto_score"]
puts "Highest Autonomous Score:"
puts "\t#{EVENTS[highest["event"]]}"
puts "\t#{match_to_words(highest)}"
puts "\t\tRed:  #{highest["red_teams"]}\t-- #{highest["red_auto"]}"
puts "\t\tBlue: #{highest["blue_teams"]}\t-- #{highest["blue_auto"]}"
puts

highest = ANALYSIS["highest_win_margin"]
puts "Highest Winning Margin:"
puts "\t#{EVENTS[highest["event"]]}"
puts "\t#{match_to_words(highest)}"
puts "\t\tRed:  #{highest["red_teams"]}\t-- #{highest["red_score"]}"
puts "\t\tBlue: #{highest["blue_teams"]}\t-- #{highest["blue_score"]}"
puts "\t\tWinning Margin: #{highest["win_margin"]}"
puts

highest = ANALYSIS["highest_win_margin_no_card"]
puts "Highest Winning Margin (only matches without a red card):"
puts "\t#{EVENTS[highest["event"]]}"
puts "\t#{match_to_words(highest)}"
puts "\t\tRed:  #{highest["red_teams"]}\t-- #{highest["red_score"]}"
puts "\t\tBlue: #{highest["blue_teams"]}\t-- #{highest["blue_score"]}"
puts "\t\tWinning Margin: #{highest["win_margin"]}"
puts

highest = ANALYSIS["highest_high_goals"]
puts "Highest High Goal Count:"
puts "\t#{EVENTS[highest["event"]]}"
puts "\t#{match_to_words(highest)}"
puts "\t\tRed:  #{highest["red_teams"]}\t-- #{highest["red_high_shots"]}"
puts "\t\tBlue: #{highest["blue_teams"]}\t-- #{highest["blue_high_shots"]}"
puts


highest = ANALYSIS["highest_low_goals"]
puts "Highest Low Goal Count:"
puts "\t#{EVENTS[highest["event"]]}"
puts "\t#{match_to_words(highest)}"
puts "\t\tRed:  #{highest["red_teams"]}\t-- #{highest["red_low_shots"]}"
puts "\t\tBlue: #{highest["blue_teams"]}\t-- #{highest["blue_low_shots"]}"
puts

highest = ANALYSIS["highest_total_goals"]
puts "Highest Total (Low + High) Goal Count:"
puts "\t#{EVENTS[highest["event"]]}"
puts "\t#{match_to_words(highest)}"
puts "\t\tRed:  #{highest["red_teams"]}\t-- #{highest["red_low_shots"]} Low + #{highest["red_high_shots"]} High"
puts "\t\tBlue: #{highest["blue_teams"]}\t-- #{highest["blue_low_shots"]} Low + #{highest["blue_high_shots"]} High"
puts

print CACHE
File.write("analysis.txt", CACHE)