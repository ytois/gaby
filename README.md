# Gaby

## How to use

```

# confing
Gaby::Client.configure do |config|
  config.account  = {{ account_email_address }}
  config.key_file = {{ p12_key_file_path }}
  config.secret   = {{ key_secret }}
end

# authorize
Gaby::Client.authorize!

# creat report model
segment = Gaby::Segment::Simple.new({type: :dimension, name: :landingPagePath, expressions: ['^/aroma', '^/esthe']})
segments = Gaby::SegmentFilter.new([segment])

report = Gaby::Report.new({
  view_id:    {{ view_id }},
  dimensions: [:landingPagePath, :segment],
  metrics:    [:sessions, :pageviews],
  dates:      "2016-11-01".."2016-11-30",
  segments:   [segments],
})


# get data
data = report.get

```


