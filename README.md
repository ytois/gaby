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



# create dynamic segment
cond1 = Gaby::SimpleSegment.dimension.where(deviceCategory: 'mobile')
cond2 = Gaby::SimpleSegment.dimension.where(pagePath: /^\/aroma/)
cond3 = Gaby::SimpleSegment.dimension.where(channelGrouping: "Direct")

segment = Gaby::Segment.new("segment_name").session(
  cond1.or(cond2),
  cond3,
)

# create filter
filter = Gaby::Filter.new(
  Gaby::Filter.dimension.where(pagePath: /^\/aroma/),
  Gaby::Filter.dimension.where(pagePath: /^\/aroma\/area/).not,
  Gaby::Filter.metric.where('pageviews > 100').not,
)

# create report model
report = Gaby::Report.new({
  view_id:    {{ view_id }},
  dimensions: [:pagePath],
  metrics:    [:sessions, :pageviews],
  dates:      [1.day.ago],
  index:      1..1000,
  filters:    filter,
  segments:   [segment],
})



# get data
data = report.get
data = report.get_all

```


