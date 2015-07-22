[azukiapp/deploy](http://images.azk.io/#/deploy)
==================

Base docker image to deploy an app using [`azk`](http://azk.io)

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
- **REMOTE_USER** (*optional, default: git*): Username created (or used if it exists) in the remote server to deploy files and run the app;
- **REMOTE_PASS** (*optional*): `REMOTE_USER`'s password. If it's a new user, a random password will be generated;
- **REMOTE_ROOT_USER** (*optional, default: root*): Root user in the remote server;
- **REMOTE_PORT** (*optional, default: 22*): SSH remote port;
- **AZK_DOMAIN** (*optional, default: azk.dev.io*): azk domain in the current namespace;
- **REMOTE_PROJECT_PATH_ID** (*optional*): By default, the project will be placed at */home/`REMOTE_USER`/`REMOTE_PROJECT_PATH_ID`* (i.e., `REMOTE_PROJECT_PATH`) in the remote server. If no value is given, a random id will be generated;
- **REMOTE_PROJECT_PATH** (*optional*): The path where the project will be stored in the remote server. If no value is given, it will be */home/`REMOTE_USER`/`REMOTE_PROJECT_PATH_ID`*;
- **RUN_SETUP** (*optional, default: true*): Boolean variable that defines if the remote server setup step should be run;
- **RUN_DEPLOY** (*optional, default: true*): Boolean variable that defines if the deploy step should be run;

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
      "/azk/deploy/src":  path("."),
      "/azk/deploy/.ssh": path("#{process.env.HOME}/.ssh")
    },
    scalable: {"default": 0, "limit": 0},
    envs: {
      REMOTE_HOST:        "`SERVER_PUBLIC_IP`",
      REMOTE_ROOT_PASS:   "`SERVER_ROOT_PASS`",
    },
  },
});
```
- Add the `AZK_HOST_IP` var to your main system http domains (so you can access it by http://`SERVER_PUBLIC_IP`)
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
        "#{process.env.AZK_HOST_IP}"
      ]
    },
  },

  // ...
});
```

- Run:
```bash
$ azk shell deploy
```

#### Usage with `docker`

To create the image `azukiapp/deploy`, execute the following command on the deploy image folder:

```sh
$ docker build -t azukiapp/deploy .
```

To run the image:

```sh
$ docker run --rm --name deploy-run \
  -v `LOCAL_PROJECT_PATH`:$(pwd) \
  -v `LOCAL_DOT_SSH_PATH`:$(echo $HOME)/.ssh \
  -e "REMOTE_HOST=`SERVER_PUBLIC_IP`" \
  -e "REMOTE_ROOT_PASS=`SERVER_ROOT_PASS`" \
  azukiapp/deploy
```

## License

Azuki Dockerfiles distributed under the [Apache License](https://github.com/azukiapp/docker-deploy/blob/master/LICENSE).
