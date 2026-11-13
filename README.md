# SecureCloud PME

Application de démonstration pour le projet de sécurité cloud (AWS Learner Lab).

## Tester en local

```bash
docker build -t securecloud-app .
docker run -d -p 5000:5000 --name test securecloud-app
curl http://localhost:5000/health
docker rm -f test
```

Résultat attendu : `{"status":"ok"}`
