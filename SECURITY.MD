### Security Issues Related to the Use of MariaDB with glftpd

Several security issues have been identified concerning the use of MariaDB with `glftpd` via the `glftpd-installer` script. These issues can affect not only the installation of `glftpd` but also other services using MariaDB on the same machine. Below is a summary of the identified issues and recommendations for addressing them.

#### 1. **Securing Scripts and Centralizing Sensitive Information**
- **Issue**: Sensitive information such as passwords is currently repeated across multiple scripts, increasing the risk of accidental exposure.

- **Recommendation**: It is recommended to centralize passwords and other sensitive information in a single configuration file, such as `/glftpd/etc/glftpd.conf`. This file should be protected with strict permissions. A comprehensive audit of existing scripts should also be conducted to identify and secure any other sensitive data.

#### 2. **Documentation and Best Practices**
- **Recommendation**: It would be helpful to include best practices for securing the installation in the project's documentation, such as password management, creating dedicated MariaDB instances, and securing scripts. This would provide users with all the necessary information for a secure and stable installation of `glftpd`.

---

### Conclusion

In summary, these modifications aim to enhance the security and stability of `glftpd` installations using MariaDB. By implementing these recommendations, we will reduce the risk of compromise and ensure better isolation of critical services on the machine.
