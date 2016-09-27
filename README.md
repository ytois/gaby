# gaby

## How to use

```
# confing
Gaby.configure do |config|
  config.key_file = "" # p12
  config.secret   = ""
  config.account  = ""
  config.view_id  = "" # Default view-id
end

# authorize
Gaby.authorize!

# creat report model
report = Gabyy::Report.new(
  dimensions: :pagePath,
  metrics: [:pageview, :sessions]
)

report.metrics << :users # add metrics

# get data
report.get(
  date: Date.new(2016, 1, 1)..Date.new(2016, 1, 31),
  index: 1..1000,
  filters: 'ga:pagePath=~^/index.html',
)
```

