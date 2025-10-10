# Guía de Contribución

Gracias por contribuir a este proyecto 
Por favor, sigue estas convenciones para mantener un flujo de trabajo limpio y consistente.

---

##  Convención de Commits

Usamos la convención **[Conventional Commits](https://www.conventionalcommits.org/es/v1.0.0/)** para todos los mensajes de commit.

### Formato:

### Tipos comunes:
- `feat:` nueva funcionalidad o característica.
- `fix:` corrección de errores.
- `chore:` tareas menores (build, dependencias, configuración).
- `docs:` cambios en documentación.
- `style:` cambios de formato o estilo (sin afectar funcionalidad).
- `refactor:` reestructuración sin cambiar comportamiento.
- `test:` cambios o agregados en pruebas.

### Ejemplos:

---

##  Versionado Semántico (SemVer)

Usamos **Semantic Versioning** para etiquetar versiones:


### Ejemplo:
- `v1.0.0` → primera versión estable.
- `v1.1.0` → se agregan nuevas funciones sin romper compatibilidad.
- `v1.1.1` → se corrigen errores menores.

###  Crear un tag al aprobar una versión estable:
```bash
# Crear el tag
git tag -a v1.0.0 -m "Versión estable inicial"

# Subir el tag al repositorio remoto
git push origin v1.0.0

---

¿Quieres que te genere también el comando para agregar este archivo a tu repo (`git add`, `commit`, `push`) y dejarlo listo en GitHub?
