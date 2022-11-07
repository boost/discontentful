# Discontentful

Ease your data discontentment!
A safe and easy ruby data migration framework for Contentful

## Installation

Install the gem and add to the application's Gemfile by executing:

  $ bundle add discontentful --group development

If bundler is not being used to manage dependencies, install the gem by executing:

  $ gem install discontentful

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

Bug reports and pull requests are welcome on GitHub at https://github.com/boost/discontentful.
