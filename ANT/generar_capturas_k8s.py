import os
from PIL import Image, ImageDraw, ImageFont

def create_terminal_window(title, lines, output_filename, width=900):
    """
    Genera una imagen simulando una terminal Linux/macOS con tipografía limpia y colores.
    """
    font_size = 14
    line_height = 22
    padding_x = 20
    padding_y = 15
    header_height = 35
    
    # Calcular alto según número de líneas
    content_height = len(lines) * line_height + (padding_y * 2)
    height = header_height + content_height

    # Crear imagen con fondo oscuro de terminal (#1E1E1E)
    img = Image.new('RGB', (width, height), color='#1E1E1E')
    draw = ImageDraw.Draw(img)

    # 1. Dibujar Barra de Ventana (Header)
    draw.rectangle([(0, 0), (width, header_height)], fill='#2D2D2D')
    
    # Botones de ventana (Rojo, Amarillo, Verde)
    draw.ellipse([(15, 11), (25, 21)], fill='#FF5F56')
    draw.ellipse([(35, 11), (45, 21)], fill='#FFBD2E')
    draw.ellipse([(55, 11), (65, 21)], fill='#27C93F')

    # Título de la ventana
    try:
        font = ImageFont.load_default()
    except Exception:
        font = None

    draw.text((width // 2 - 100, 10), title, fill='#A0A0A0', font=font)

    # 2. Dibujar Contenido (Líneas de la Terminal)
    y_curr = header_height + padding_y

    for line in lines:
        x_curr = padding_x
        # La línea puede ser una lista de tuplas: [("texto", "color_hex"), ...]
        if isinstance(line, list):
            for text_part, color in line:
                draw.text((x_curr, y_curr), text_part, fill=color, font=font)
                # Estimación de ancho por carácter en fuente default
                x_curr += len(text_part) * 6.2
        else:
            draw.text((x_curr, y_curr), line, fill='#CCCCCC', font=font)
        
        y_curr += line_height

    # Guardar Imagen
    img.save(output_filename)
    print(f"✅ Imagen generada exitosamente: {output_filename}")


def generate_all_k8s_screenshots():
    # Prompt común para la terminal
    p_user = [("andres@k8s-master", "#38BDF8"), (":~$ ", "#F43F5E")]

    # -------------------------------------------------------------------------
    # CAPTURA 1: Despliegue Inicial (3 Réplicas)
    # -------------------------------------------------------------------------
    lines_cap1 = [
        p_user + [("kubectl apply -f smartcontract-deployment.yaml", "#FFFFFF")],
        [("deployment.apps/smartcontract-deployment created", "#4ADE80")],
        [("service/smartcontract-service created", "#4ADE80")],
        [("", "#FFFFFF")],
        p_user + [("kubectl get pods -l app=smartcontract -o wide", "#FFFFFF")],
        [("NAME                                        READY   STATUS    RESTARTS   AGE   IP            NODE", "#94A3B8")],
        [("smartcontract-deployment-7d5f8c6b9d-4x8ab   1/1     Running   0          18s   10.244.1.12   node-1", "#E2E8F0")],
        [("smartcontract-deployment-7d5f8c6b9d-9z2pq   1/1     Running   0          18s   10.244.2.15   node-2", "#E2E8F0")],
        [("smartcontract-deployment-7d5f8c6b9d-m7k3w   1/1     Running   0          18s   10.244.1.13   node-1", "#E2E8F0")],
        [("", "#FFFFFF")],
        p_user + [("kubectl get deployment smartcontract-deployment", "#FFFFFF")],
        [("NAME                       READY   UP-TO-DATE   AVAILABLE   AGE", "#94A3B8")],
        [("smartcontract-deployment   3/3     3            3           25s", "#E2E8F0")]
    ]
    create_terminal_window("bash - Despliegue Inicial (3 Réplicas)", lines_cap1, "01_despliegue_inicial_3_replicas.png")

    # -------------------------------------------------------------------------
    # CAPTURA 2: Escalado en Caliente a 5 Réplicas
    # -------------------------------------------------------------------------
    lines_cap2 = [
        p_user + [("kubectl scale deployment/smartcontract-deployment --replicas=5", "#FFFFFF")],
        [("deployment.apps/smartcontract-deployment scaled", "#4ADE80")],
        [("", "#FFFFFF")],
        p_user + [("kubectl get pods -l app=smartcontract", "#FFFFFF")],
        [("NAME                                        READY   STATUS              RESTARTS   AGE", "#94A3B8")],
        [("smartcontract-deployment-7d5f8c6b9d-4x8ab   1/1     Running             0          2m10s", "#E2E8F0")],
        [("smartcontract-deployment-7d5f8c6b9d-9z2pq   1/1     Running             0          2m10s", "#E2E8F0")],
        [("smartcontract-deployment-7d5f8c6b9d-m7k3w   1/1     Running             0          2m10s", "#E2E8F0")],
        [("smartcontract-deployment-7d5f8c6b9d-f82kc   1/1     ContainerCreating   0          3s", "#FACC15")],
        [("smartcontract-deployment-7d5f8c6b9d-k29lx   1/1     ContainerCreating   0          3s", "#FACC15")],
        [("", "#FFFFFF")],
        p_user + [("kubectl get pods -l app=smartcontract", "#FFFFFF")],
        [("NAME                                        READY   STATUS    RESTARTS   AGE", "#94A3B8")],
        [("smartcontract-deployment-7d5f8c6b9d-4x8ab   1/1     Running   0          2m25s", "#E2E8F0")],
        [("smartcontract-deployment-7d5f8c6b9d-9z2pq   1/1     Running   0          2m25s", "#E2E8F0")],
        [("smartcontract-deployment-7d5f8c6b9d-m7k3w   1/1     Running   0          2m25s", "#E2E8F0")],
        [("smartcontract-deployment-7d5f8c6b9d-f82kc   1/1     Running   0          18s", "#E2E8F0")],
        [("smartcontract-deployment-7d5f8c6b9d-k29lx   1/1     Running   0          18s", "#E2E8F0")]
    ]
    create_terminal_window("bash - Escalado Dinámico a 5 Réplicas", lines_cap2, "02_escalado_5_replicas.png")

    # -------------------------------------------------------------------------
    # CAPTURA 3: Rolling Update (Actualización de Imagen v1.0 -> v2.0)
    # -------------------------------------------------------------------------
    lines_cap3 = [
        p_user + [("kubectl set image deployment/smartcontract-deployment smartcontract=smartcontract-app:v2.0", "#FFFFFF")],
        [("deployment.apps/smartcontract-deployment image updated", "#4ADE80")],
        [("", "#FFFFFF")],
        p_user + [("kubectl rollout status deployment/smartcontract-deployment", "#FFFFFF")],
        [("Waiting for deployment \"smartcontract-deployment\" rollout to finish: 2 out of 5 new replicas have been updated...", "#FACC15")],
        [("Waiting for deployment \"smartcontract-deployment\" rollout to finish: 3 of 5 updated replicas are available...", "#FACC15")],
        [("deployment \"smartcontract-deployment\" successfully rolled out", "#4ADE80")],
        [("", "#FFFFFF")],
        p_user + [("kubectl get pods -l app=smartcontract", "#FFFFFF")],
        [("NAME                                        READY   STATUS    RESTARTS   AGE", "#94A3B8")],
        [("smartcontract-deployment-869c4f5a1e-a12b3   1/1     Running   0          22s", "#E2E8F0")],
        [("smartcontract-deployment-869c4f5a1e-b34c5   1/1     Running   0          20s", "#E2E8F0")],
        [("smartcontract-deployment-869c4f5a1e-c56d7   1/1     Running   0          18s", "#E2E8F0")],
        [("smartcontract-deployment-869c4f5a1e-d78e9   1/1     Running   0          15s", "#E2E8F0")],
        [("smartcontract-deployment-869c4f5a1e-e90f1   1/1     Running   0          12s", "#E2E8F0")]
    ]
    create_terminal_window("bash - Rolling Update a Versión v2.0", lines_cap3, "03_rolling_update_v2.png")

    # -------------------------------------------------------------------------
    # CAPTURA 4: Historial de ReplicaSets y Rollout
    # -------------------------------------------------------------------------
    lines_cap4 = [
        p_user + [("kubectl get rs -l app=smartcontract", "#FFFFFF")],
        [("NAME                                   DESIRED   CURRENT   READY   AGE", "#94A3B8")],
        [("smartcontract-deployment-7d5f8c6b9d   0         0         0       8m12s", "#64748B")],
        [("smartcontract-deployment-869c4f5a1e   5         5         5       2m45s", "#E2E8F0")],
        [("", "#FFFFFF")],
        p_user + [("kubectl rollout history deployment/smartcontract-deployment", "#FFFFFF")],
        [("deployment.apps/smartcontract-deployment", "#FFFFFF")],
        [("REVISION  CHANGE-CAUSE", "#94A3B8")],
        [("1         kubectl apply -f smartcontract-deployment.yaml --record", "#E2E8F0")],
        [("2         kubectl set image deployment/smartcontract-deployment smartcontract=smartcontract-app:v2.0 --record", "#E2E8F0")]
    ]
    create_terminal_window("bash - Historial de ReplicaSets y Revisiones", lines_cap4, "04_historial_replicasets.png")


def generate_architecture_diagram(output_filename="00_diagrama_arquitectura_k8s.png"):
    """
    Genera un diagrama esquemático y limpio de la arquitectura de Kubernetes.
    """
    width, height = 900, 500
    img = Image.new('RGB', (width, height), color='#F8FAFC')
    draw = ImageDraw.Draw(img)

    try:
        font = ImageFont.load_default()
    except Exception:
        font = None

    # Fondo Clúster
    draw.rectangle([(30, 30), (870, 470)], fill='#EFF6FF', outline='#3B82F6', width=2)
    draw.text((50, 45), "Clúster de Kubernetes (K8s Cluster)", fill='#1E3A8A', font=font)

    # Objeto Service
    draw.rectangle([(70, 100), (220, 430)], fill='#DBEAFE', outline='#2563EB', width=2)
    draw.text((85, 115), "Service (NodePort/CIP)", fill='#1E40AF', font=font)
    draw.text((85, 140), "Port: 80\nTargetPort: 8545", fill='#1E3A8A', font=font)

    # Objeto Deployment
    draw.rectangle([(260, 100), (840, 430)], fill='#F1F5F9', outline='#64748B', width=2)
    draw.text((280, 115), "Deployment: smartcontract-deployment", fill='#0F172A', font=font)

    # Objeto ReplicaSet
    draw.rectangle([(280, 150), (820, 410)], fill='#FFFFFF', outline='#0EA5E9', width=2)
    draw.text((300, 165), "ReplicaSet (Replicas: 5)", fill='#0369A1', font=font)

    # Pods (3 mostrados de forma gráfica)
    pod_positions = [(310, 200), (475, 200), (640, 200)]
    for idx, (px, py) in enumerate(pod_positions, 1):
        draw.rectangle([(px, py), (px + 150, py + 190)], fill='#ECFDF5', outline='#10B981', width=2)
        draw.text((px + 10, py + 10), f"Pod {idx}", fill='#065F46', font=font)
        draw.text((px + 10, py + 30), "Status: Running", fill='#047857', font=font)

        # Contenedor dentro del Pod
        draw.rectangle([(px + 10, py + 65), (px + 140, py + 175)], fill='#FFFFFF', outline='#059669', width=1)
        draw.text((px + 15, py + 75), "Contenedor:", fill='#065F46', font=font)
        draw.text((px + 15, py + 95), "smartcontract:v2", fill='#0f172a', font=font)
        draw.text((px + 15, py + 120), "• Node.js / Web3", fill='#475569', font=font)
        draw.text((px + 15, py + 140), "• Smart Contract", fill='#475569', font=font)

    # Flechas de conexión (Líneas)
    draw.line([(220, 265), (260, 265)], fill='#2563EB', width=3)

    img.save(output_filename)
    print(f"✅ Diagrama generado exitosamente: {output_filename}")


if __name__ == "__main__":
    print("🚀 Iniciando generación de imágenes para el informe K8s...")
    generate_all_k8s_screenshots()
    generate_architecture_diagram()
    print("\n🎉 ¡Todas las imágenes se crearon correctamente en el directorio actual!")