# frozen_string_literal: true

require 'rainbow'
require 'yaml'
require 'diffy'
require 'ruby-progressbar'
require 'highline'
require 'contentful/management'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/object/deep_dup'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/string/inflections'

require_relative "discontentful/version"
require_relative "discontentful/rich_text"
require_relative "discontentful/stats"
require_relative "discontentful/contentful_updater"
require_relative "discontentful/transformation"
require_relative 'discontentful/railtie' if defined?(Rails)

module Discontentful
  class Error < StandardError; end

  def self.get_environment
    cli = HighLine.new

    puts Rainbow("Please provide a personal access token for your contentful user.").yellow
    puts Rainbow("Go to https://app.contentful.com/account/profile/cma_tokens to make one)").yellow
    puts Rainbow("We recommend you generate a token each time you need it, and revoke it when you're finished").yellow
    token = cli.ask("Enter your token:  ") { |q| q.echo = 'x' }
    puts
    client = Contentful::Management::Client.new(token)
    spaces = client.spaces.all
    puts Rainbow("Choose a space: ").yellow
    spaces.each_with_index do |s, index|
      puts "#{index+1}. #{s.id}: #{s.name}"
    end
    space_index = cli.ask("Space: ", Integer) { |q| q.in = 1..spaces.count }
    space = spaces.to_a[space_index-1]

    puts
    puts Rainbow("Using space #{space.id}: #{space.name}").green

    puts Rainbow("Choose an environment").yellow
    envs = space.environments.all
    envs.each_with_index do |e, index|
      puts "#{index+1}. #{e.id}"
    end
    env_index = cli.ask("Environment: ", Integer) { |q| q.in = 1..envs.count }
    environment = envs.to_a[env_index-1]
    puts
    puts Rainbow("Using environment #{environment.id}").green

    client = Contentful::Management::Client.new(
      token, dynamic_entries: { space.id => environment.id }, default_locale: 'en-NZ'
    )
    environment = client.environments(space.id).find(environment.id)

    cli.say "Use the #{Rainbow(environment.id).white} environment in #{Rainbow("#{space.id}: #{space.name}").white}?"
    unless cli.agree(Rainbow("Are you sure? (y/n)").yellow)
      abort
    end
    environment
  end
end
