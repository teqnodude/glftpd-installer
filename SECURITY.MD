### Security Issues Related to the Use of MariaDB with glftpd

Several security issues have been identified concerning the use of MariaDB with `glftpd` via the `glftpd-installer` script. These issues can affect not only the installation of `glftpd` but also other services using MariaDB on the same machine. Below is a summary of the identified issues and recommendations for addressing them.

#### 1. **Modification of MariaDB `datadir`**
- **Issue**: Currently, if a pre-existing MariaDB instance is already installed on the machine (for a purpose other than `glftpd`), its `datadir` is changed to `/glftpd/backup/mysql`. This modification occurs, for instance, when the section-traffic module is activated, where the file `/etc/mysql/mariadb.conf.d/50-server.cnf` is replaced after the original is backed up. This behavior is also found in the `tur-trial3` script.
  - Links to the relevant code:
    - [section-traffic.inc](https://github.com/teqnodude/glftpd-installer/blob/master/packages/modules/section-traffic/section-traffic.inc#L34)
    - [tur-trial3.inc](https://github.com/teqnodude/glftpd-installer/blob/master/packages/modules/tur-trial3/tur-trial3.inc#L40)
  
- **Impact**: This modification of the `datadir` can cause service disruptions for existing databases, preventing other services that depend on them from functioning properly. This could lead to database connection losses and interruptions of critical services.
  
- **Recommendation**: Before modifying the `datadir`, it is advisable to detect if a pre-existing MariaDB instance is running. If so, consider either creating a new dedicated instance for `glftpd` or carefully configuring the existing instance to avoid conflicts. The following documentation may be helpful for configuring multiple MariaDB instances:
  - [Running Multiple MariaDB Server Processes](https://mariadb.com/kb/en/running-multiple-mariadb-server-processes/)
  - [mariadbd-multi](https://mariadb.com/kb/en/mariadbd-multi/)

#### 2. **Securing Scripts and Centralizing Sensitive Information**
- **Issue**: Sensitive information such as passwords is currently repeated across multiple scripts, increasing the risk of accidental exposure.

- **Recommendation**: It is recommended to centralize passwords and other sensitive information in a single configuration file, such as `/glftpd/etc/glftpd.conf`. This file should be protected with strict permissions. A comprehensive audit of existing scripts should also be conducted to identify and secure any other sensitive data.

#### 3. **Documentation and Best Practices**
- **Recommendation**: It would be helpful to include best practices for securing the installation in the project's documentation, such as password management, creating dedicated MariaDB instances, and securing scripts. This would provide users with all the necessary information for a secure and stable installation of `glftpd`.

---

### Conclusion

In summary, these modifications aim to enhance the security and stability of `glftpd` installations using MariaDB. By implementing these recommendations, we will reduce the risk of compromise and ensure better isolation of critical services on the machine.
