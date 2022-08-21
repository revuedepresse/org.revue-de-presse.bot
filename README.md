# Twitter Bot Header 🤖

## Documentation

```shell
make help
```

## Requirements

Install [git](https://git-scm.com/downloads).
> Git is a free and open source distributed version control system designed
> to handle everything from small to very large projects with speed and efficiency.

Install [Docker Docker Engine](https://docs.docker.com/engine/install/).
> Docker Engine is an open source containerization technology for building and containerizing your applications.

Install [Docker Compose](https://docs.docker.com/compose/install/).
> Compose is a tool for defining and running multi-container Docker applications.

## Configuration

```shell
API_KEY='_' \
API_SECRET='_' \
ACCESS_TOKEN='_' \
ACCESS_TOKEN_SECRET='_' \
SCREEN_NAME='_' \
make configure
```

To get the API keys, you need to [apply for a Twitter Developer account](https://developer.twitter.com/en/apply-for-access).  
It's free and take ~5 minutes.

Lastly, add a banner template file named `public/images/twitter-banner-template.png`.

The banner template file *should be* an image in PNG format.

Besides, you'll have to resize it by following the [official sizing recommendations](https://help.twitter.com/en/managing-your-account/common-issues-when-uploading-profile-photo):
- width: 1500px,
- height: 500px

i.e. 1500x500 in px

## Installation

```shell
WORKER="org.revue-de-presse.twitter-header-bot"
COMPOSE_PROJECT_NAME="$(echo "${WORKER}" | tr '.' '_')"
/bin/bash -c '(  make start )'
```

## License

This project was heavily inspired by [Guillaume REYGNER]'s Twitter Header Bot,  
available from its standalone repository:  
[github.com/guillaume-rygn/Twitter-header-bot](https://github.com/guillaume-rygn/Twitter-header-bot)

MIT License

See LICENSE.md.
