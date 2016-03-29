require 'open-uri'
require 'json'

require 'sqlite3'

EVENT=ARGV.select { |arg| !arg.start_with?("-") }
FLAGS=ARGV.select { |arg| arg.start_with?("-") }

FORCE=FLAGS.include? "--force"

@db = SQLite3::Database.new "matches.db"
begin 
    @db.execute <<-SQL
        create table matches (
            match varchar(30),
            event varchar(30),
            comp_level varchar(30),
            match_number int,
            set_number int,
            blue_teams varchar(50),
            red_teams varchar(50),
            blue_teleop int, blue_auto int, blue_penalty int, blue_score int,
            red_teleop int, red_auto int, red_penalty int, red_score int,
            UNIQUE(match)
        )
    SQL
rescue  # Table Already Exists
end

begin 
    @db.execute <<-SQL
        create table events (
            event varchar(30),
            name varchar(50),
            UNIQUE(event)
        )
    SQL
rescue  # Table Already Exists
end

def insert match
    blue_score_bd = match["score_breakdown"]["blue"]
    red_score_bd  = match["score_breakdown"]["red"]
    datum = [
        match["key"], match["event_key"], match["comp_level"], match["match_number"], match["set_number"],
        match["alliances"]["blue"]["teams"].map { |x| x.sub("frc", "") }.join(" "),
        match["alliances"]["red"]["teams"].map { |x| x.sub("frc", "") }.join(" "),
        blue_score_bd["teleopPoints"], blue_score_bd["autoPoints"], blue_score_bd["foulPoints"], blue_score_bd["totalPoints"],
        red_score_bd["teleopPoints"], red_score_bd["autoPoints"], red_score_bd["foulPoints"], red_score_bd["totalPoints"]
    ]
    
    begin
        @db.execute("INSERT INTO matches VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", datum)
    rescue SQLite3::ConstraintException      # Unique
    end
end

def has_occured match
    return !(match["score_breakdown"].nil? || match["score_breakdown"]["red"].nil? || match["score_breakdown"]["red"]["totalPoints"].nil?)
end

def existsCheck id
    @db.execute( "select 1 from matches where match = ?", [id] ).length > 0
end

events_all = JSON.parse open("http://www.thebluealliance.com/api/v2/events/2016", "X-TBA-App-Id" => "jacinta:scorefinder:v0.1").read
events_all.each do |event|
    next unless EVENT.length == 0 || EVENT.include?(event["key"])
    e = event["key"]
    
    begin
        @db.execute("INSERT INTO events VALUES (?, ?)", e, event["name"])
    rescue SQLite3::ConstraintException      # Unique
    end
    
    matches = JSON.parse open("http://www.thebluealliance.com/api/v2/event/#{e}/matches", "X-TBA-App-Id" => "jacinta:scorefinder:v0.1").read
    matches.each do |match|
        print "#{match["key"]}..."
        if (existsCheck(match["key"]) && !FORCE) 
            print " SKIP! \n"
            next
        end
        insert match if has_occured match
        print " DONE! \n"
    end
end