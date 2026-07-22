import time
import subprocess
import os
from rich.console import Console
from rich.table import Table

console = Console()

def run_cmd(cmd):
    """Ejecuta comandos de consola y retorna la salida."""
    result = subprocess.run(cmd, shell=True, text=True, capture_output=True)
    return result.stdout.strip()

def capture_k8s_status(step_name):
    """Imprime y simula la captura visual del estado del clúster."""
    console.rule(f"[bold cyan]EVIDENCIA: {step_name}[/bold cyan]")
    
    pods = run_cmd("kubectl get pods -o wide")
    rs = run_cmd("kubectl get rs")
    rollout = run_cmd("kubectl rollout status deployment/smart-contract-deployment --timeout=30s")

    console.print("[bold green]>>> kubectl get pods -o wide:[/bold green]")
    console.print(pods)
    console.print("\n[bold yellow]>>> kubectl get rs:[/bold yellow]")
    console.print(rs)
    console.print("\n[bold magenta]>>> Estado del Rollout:[/bold magenta]")
    console.print(rollout)
    
    # Guardar log formateado para inclusión en el informe / screenshots
    os.makedirs("evidence", exist_ok=True)
    with open(f"evidence/{step_name.lower().replace(' ', '_')}.txt", "w") as f:
        f.write(f"=== {step_name} ===\n\nPODS:\n{pods}\n\nREPLICASETS:\n{rs}\n\nROLLOUT STATUS:\n{rollout}\n")

def main():
    console.print("[bold blue]Iniciando Orquestación del Smart Contract en Kubernetes...[/bold blue]\n")

    # Paso 1: Aplicar el Deployment Inicial (3 réplicas)
    console.print("[bold]Paso 1: Aplicando Deployment inicial (3 réplicas)...[/bold]")
    run_cmd("kubectl apply -f k8s/deployment-v1.yaml")
    time.sleep(10)  # Esperar a que se levanten los pods
    capture_k8s_status("Paso 1 - Despliegue Inicial (3 Replicas)")

    # Paso 2: Cambio en caliente 1 -> Escalado a 5 réplicas
    console.print("\n[bold]Paso 2: Cambio en caliente #1 - Escalando a 5 réplicas...[/bold]")
    run_cmd("kubectl scale deployment/smart-contract-deployment --replicas=5")
    time.sleep(8)
    capture_k8s_status("Paso 2 - Escalado a 5 Replicas")

    # Paso 3: Cambio en caliente 2 -> Rolling Update de la imagen
    console.print("\n[bold]Paso 3: Cambio en caliente #2 - Rolling Update (Actualización de Contenedor/Versión)...[/bold]")
    run_cmd("kubectl set image deployment/smart-contract-deployment contract-container=trufflesuite/ganache-cli:v6.12.2")
    time.sleep(12)
    capture_k8s_status("Paso 3 - Rolling Update Completado")

    console.print("\n[bold green]¡Orquestación finalizada exitosamente! Evidencias guardadas en la carpeta /evidence.[/bold green]")

if __name__ == "__main__":
    main()