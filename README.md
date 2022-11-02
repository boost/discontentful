# Contentful Transformation Toolkit

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/contentful/transformation/toolkit`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Install the gem and add to the application's Gemfile by executing:

  $ bundle add contentful-transformation-toolkit

If bundler is not being used to manage dependencies, install the gem by executing:

  $ gem install contentful-transformation-toolkit

## Usage

TODO: Write usage instructions here

```ruby 
module ContentfulTransformations
  class FileHyperlinksToEmbeddedAssetsPages < Discontentful::Transformation do
    source_content_model 'page'

    def each(page) 
      new_body = migrate_rich_text(page.body)
      new_intro = migrate_rich_text(page.intro)

      update_entry(page, body: new_body, intro: new_intro)
    end

  private

    def migrate_rich_text(rich_text)
      replace_rich_text_node(rich_text, nodeType: 'hyperlink') do |node|
        asset_title = node["data"]["uri"].match /^(https?:\/\/(www\.)?archives\.govt\.nz)?\/files\/(?<name>.*)$/

        next unless asset_title.present?

        asset = find_asset(title: asset_title)
        if asset.nil?
          error("Could not find asset with title: #{asset_title}")
          next
        end

        {
          "nodeType": 'asset-hyperlink', 
          "data": {
            "target"=>{
              "sys"=>{"id"=>asset["_id"], "type"=>"Link", "linkType"=>"Asset"}
            }
          },
          "content" => node["content"]
        }
      end
    end
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/contentful-transformation-toolkit.
