[azukiapp/deploy](http://images.azk.io/#/deploy)
==================

Base docker image to deploy an app using [`azk`](http://azk.io)

Initial Considerations
---
We strongly recommend you to use Ubuntu 14.04 x86-64 in the target server.
Using this image with any other OS in the target server is untested yet and it's potentially broken.

Versions (tags)
---

<versions>
- [`latest`](https://github.com/azukiapp/docker-deploy/blob/master/latest/Dockerfile)
</versions>

Image content:
---

- Ubuntu 14.04
- [Ansible](http://www.ansible.com)
- [SSHPass](http://sourceforge.net/projects/sshpass/)

### Configuration
The following environment variables are available for configuring the deployment using this image:

- **REMOTE_HOST**: Deploy server's public IP;
- **REMOTE_ROOT_PASS** (*optional*): Deploy server's root password. It's optional because you can have added your public ssh key into the authorized_keys files in the remote server;
- **LOCAL_PROJECT_PATH**: (*optional, default: `/azk/deploy/src`*) Project source code path;
- **LOCAL_DOT_SSH_PATH** (*optional, default: `/azk/deploy/.ssh`*): Path containing SSH keys. If no path is given, a new SSH public/private key pair will be generated;
- **LOCAL_DOT_CONFIG_PATH** (*optional, default: `/azk/deploy/.config`*): Path to be mapped as a persistent folder on Azkfile.js. Used to cache deploy information;
- **REMOTE_USER** (*optional, default: git*): Username created (or used if it exists) in the remote server to deploy files and run the app;
- **REMOTE_PASS** (*optional*): `REMOTE_USER`'s password. If it's a new user, a random password will be generated;
- **REMOTE_ROOT_USER** (*optional, default: root*): Root user in the remote server;
- **REMOTE_PORT** (*optional, default: 22*): SSH remote port;
- **GIT_REF** (*optional, default: master*): Git reference (branch, commit SHA1 or tag) to be deployed;
- **AZK_DOMAIN** (*optional, default: azk.dev.io*): azk domain in the current namespace;
- **HOST_DOMAIN** (*optional*): Domain name which you'll use to access the remote server;
- **AZK_RESTART_COMMAND** (*optional, default: azk restart -R*): command to executed after each git push;
- **REMOTE_PROJECT_PATH_ID** (*optional*): By default, the project will be placed at */home/`REMOTE_USER`/`REMOTE_PROJECT_PATH_ID`* (i.e., `REMOTE_PROJECT_PATH`) in the remote server. If no value is given, a random id will be generated;
- **REMOTE_PROJECT_PATH** (*optional*): The path where the project will be stored in the remote server. If no value is given, it will be */home/`REMOTE_USER`/`REMOTE_PROJECT_PATH_ID`*;
- **RUN_SETUP** (*optional, default: true*): Boolean variable that defines if the remote server setup step should be run;
- **RUN_CONFIGURE** (*optional, default: true*): Boolean variable that defines if the remote server configuration should be run;
- **RUN_DEPLOY** (*optional, default: true*): Boolean variable that defines if the deploy step should be run;
- **DISABLE_ANALYTICS_TRACKER** (*optional, default: false*): Boolean variable that defines either azk should track deploy anonymous data or not;
- **ENV_FILE** (*optional, default: `.env`*): The `.env file` path that will be copied to remote server.

### Usage

Consider you want to deploy your app in a server which public IP is `SERVER_PUBLIC_IP` and root user's password is `SERVER_ROOT_PASS`, and your local SSH keys are placed at `LOCAL_DOT_SSH_PATH` (usually this path is `$HOME`/.ssh). Remember that passing a root password is optional, since you can always put your local SSH public key into `$HOME/.ssh/authorized_keys` file in the host server.

#### Usage with `azk`

Example of using this image with [azk](http://azk.io):

- Add the `deploy` system to your Azkfile.js:

```js
/**
 * Documentation: http://docs.azk.io/Azkfile.js
 */

// Adds the systems that shape your system
systems({
  // ...

  deploy: {
    image: {"docker": "azukiapp/deploy"},
    mounts: {
      "/azk/deploy/src":     path("."),
      "/azk/deploy/.ssh":    path("#{env.HOME}/.ssh"),
      "/azk/deploy/.config": persistent("deploy-config"),
    },
    scalable: {"default": 0, "limit": 0},
    envs: {
      REMOTE_HOST:        "`SERVER_PUBLIC_IP`",
      REMOTE_ROOT_PASS:   "`SERVER_ROOT_PASS`",
    },
  },
});
```

- Add the `HOST_DOMAIN` (if any) and `HOST_IP` var to your main system http domains (so you can access it by http://`SERVER_PUBLIC_IP` or http://`YOUR_CUSTOM_DOMAIN`). Please note the order matter.

```js
/**
 * Documentation: http://docs.azk.io/Azkfile.js
 */

// Adds the systems that shape your system
systems({
  example: {
    // ...
    http: {
      domains: [
        // ...
        "#{env.HOST_DOMAIN}",
        "#{env.HOST_IP}"
      ]
    },
  },

  // ...
});
```

- Run:
```bash
$ azk deploy
```

- Customizing `AZK_RESTART_COMMAND` for a specific deploy:
```bash
$ azk deploy -e AZK_RESTART_COMMAND="azk restart -R -vvvv --rebuild"
```

#### Usage with `docker`

To create the image `azukiapp/deploy`, execute the following command on the deploy image folder:

```sh
$ docker build -t azukiapp/deploy .
```

To run the image:

```sh
$ docker run --rm --name deploy-run \
  -v $(pwd):/azk/deploy/src \
  -v $HOME/.ssh:/azk/deploy/.ssh \
  -e "REMOTE_HOST=`SERVER_PUBLIC_IP`" \
  -e "REMOTE_ROOT_PASS=`SERVER_ROOT_PASS`" \
  azukiapp/deploy
```

Before running, replace `SERVER_PUBLIC_IP` and `SERVER_ROOT_PASS` with the actual values.

## License

Azuki Dockerfiles distributed under the [Apache License](https://github.com/azukiapp/docker-deploy/blob/master/LICENSE).
