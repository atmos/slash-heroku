# SlashHeroku <a href="https://slash-heroku.atmos.org/auth/slack"><img alt="Add to Slack" height="40" width="139" src="https://platform.slack-edge.com/img/add_to_slack.png" srcset="https://platform.slack-edge.com/img/add_to_slack.png 1x, https://platform.slack-edge.com/img/add_to_slack@2x.png 2x" /></a>

[SlashHeroku](https://github.com/atmos/slash-heroku) is a web app for working with the [Heroku Platform API](https://devcenter.heroku.com/articles/platform-api-reference) via a `/heroku` command in Slack.

![](https://cloud.githubusercontent.com/assets/38/22093624/1d054b38-ddbc-11e6-9f48-0ba4c0ddf51c.png)

## Development

```
$ ./bin/setup
$ rails s
```

### Tests

The full test suite can be run with:

```
$ ./bin/cibuild
```

### Deploying to Heroku

* [Create a GitHub OAuth app](https://github.com/settings/applications/new)
* [Create a Heroku OAuth app](https://dashboard.heroku.com/account/clients/new)
* [Create a Slack app](https://api.slack.com/apps/new)
* [Create this app on Heroku](https://heroku.com/deploy?template=https://github.com/atmos/slash-heroku)
* heroku plugins:install heroku-redis
* heroku redis:promote HEROKU_REDIS_SOMECOLOR -a heroku-app-you-created
