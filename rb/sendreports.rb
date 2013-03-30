#!/usr/local/bin/ruby -w
# sendreports.rb - Rainbow's End is an empire building strategy PBEM game
# rules (C)2001 Russell Wallace, source code (C)2001 Stefan Matthias Aust

require 'net/pop'
require 'net/smtp'

$pop_before_smtp = true
$popserver = 'post.strato.de'
$popuser = 'orders@3plus4.de'
$poppassword = 'rainbow'

$smtpserver = $popserver

# to whom shall we send which files
 
load "send.txt" # defines $reports and $turn

# my ISP uses pop before smtp protocol

if $pop_before_smtp
  pop = Net::POP3.new($popserver)
  pop.start($popuser, $poppassword)
  pop.finish
end

# now we can send...

smtp = Net::SMTP.start($smtpserver)
$reports.each do |file, to|
  $stderr.print "sending #{file} to #{to}..."
  smtp.ready('rainbowsend@3plus4.de', to) do |a|
    a.write "To: #{to}\n"
    a.write "Subject: [RE] Rainbow's End Turn #{$turn}\n"
    a.write "\n"
    File.foreach(file) do |line|
      a.write line
    end
  end
  $stderr.print "done\n"
end

