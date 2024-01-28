# Seal

Seal is a assistant tool using Kubeseal (Sealed Secrets) to encrypt Kubernetes Secrets.

## Usage

```
docker run -it seanlw/seal my-secret --namespace default --literal foo=bar --cert public-cert.pem
```

Options:
```
-c, --cert string       Public certificate to use for encrypting secrets
-e, --env string        If present, the .env file that references key=val pairs
-f, --file string       If present, items that can be source from file
--help                  Print this help message
-l, --literal string    If present, the key and literal value to insert (i.e. key=val)
-n, --namespace string  If present, the namespace scope for this CLI request
```

### Certificates

You can load public certificates to encrypt your secrets:

```
docker run -it -v /path/to/your/certs:/certs seanlw/seal my-secret --cert your-public-cert.pem 
```

### .env and files

You can load `.env` or other files to add to your secrets

```
docker run -it -v /path/to/your/files:/secrets seanlw/seal my-secret --env your-secrets.env
```
