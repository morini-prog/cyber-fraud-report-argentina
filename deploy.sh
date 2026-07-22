#!/bin/bash
# Script de despliegue automatizado para el Informe de Estafas Virtuales con IA en Argentina
# Desarrollado por Antigravity

set -e

REPO_NAME="cyber-fraud-report-argentina"
echo "=== Iniciando proceso de publicación y despliegue ==="

# 1. Obtener usuario de GitHub
echo "Obteniendo usuario autenticado en GitHub..."
GITHUB_USER=$(gh api user -q .login)
if [ -z "$GITHUB_USER" ]; then
    echo "Error: No se pudo obtener el usuario de GitHub. Asegúrate de estar autenticado con 'gh auth login'."
    exit 1
fi
echo "Usuario detectado: $GITHUB_USER"

# 2. Inicializar repositorio Git local si no existe
if [ ! -d ".git" ]; then
    echo "Inicializando repositorio Git local..."
    git init -b main
else
    echo "Repositorio Git ya inicializado localmente."
fi

# 3. Configurar usuario local para evitar fallos de commit
echo "Configurando firma de commits local..."
git config user.name "Antigravity Assistant"
git config user.email "antigravity@google.com"

# 4. Agregar archivos y hacer commit inicial
echo "Agregando archivos al área de preparación..."
git add index.html deploy.sh

# Comprobar si hay cambios para hacer commit
if git diff-index --quiet HEAD --; then
    echo "No hay cambios nuevos para realizar commit."
else
    echo "Realizando commit inicial..."
    git commit -m "feat: initial commit with CTI report dashboard"
fi

# 5. Crear repositorio remoto si no existe
echo "Verificando si el repositorio remoto ya existe en GitHub..."
if gh repo view "$GITHUB_USER/$REPO_NAME" >/dev/null 2>&1; then
    echo "El repositorio remoto '$GITHUB_USER/$REPO_NAME' ya existe."
    # Asegurarnos de que el origen remoto esté bien configurado
    if git remote | grep origin >/dev/null; then
        git remote set-url origin "https://github.com/$GITHUB_USER/$REPO_NAME.git"
    else
        git remote add origin "https://github.com/$GITHUB_USER/$REPO_NAME.git"
    fi
else
    echo "Creando repositorio público en GitHub..."
    gh repo create "$REPO_NAME" --public --source=. --remote=origin
fi

# 6. Empujar los cambios a la rama principal (main)
echo "Empujando cambios a la rama principal 'main' en GitHub..."
git push -u origin main --force

# 7. Habilitar y configurar GitHub Pages
echo "Habilitando y configurando GitHub Pages para la rama 'main'..."
# Verificar si Pages ya está habilitado
if gh api "/repos/$GITHUB_USER/$REPO_NAME/pages" >/dev/null 2>&1; then
    echo "GitHub Pages ya está habilitado para este repositorio."
else
    # Habilitar Pages
    gh api -X POST "/repos/$GITHUB_USER/$REPO_NAME/pages" \
        -f source='{"branch":"main","path":"/"}' >/dev/null
    echo "GitHub Pages habilitado exitosamente."
fi

# 8. Reportar resultados finales
PUBLIC_URL="https://$GITHUB_USER.github.io/$REPO_NAME/"
echo ""
echo "=== PROCESO COMPLETADO EXITOSAMENTE ==="
echo "Código publicado en: https://github.com/$GITHUB_USER/$REPO_NAME"
echo "Despliegue de GitHub Pages configurado."
echo "La URL de tu página web será: $PUBLIC_URL"
echo "========================================"
