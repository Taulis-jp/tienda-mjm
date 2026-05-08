package cl.triskeledu.envios.model;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;

@Entity
@Table(
    name = "envio",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_envio_codigo_pedido", columnNames = "codigo_pedido")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Envio {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "codigo_pedido", referencedColumnName = "codigo_pedido", nullable = false, unique = true)
    private PedidoProy pedido;

    @Enumerated(EnumType.STRING)
    @Column(name = "estado", nullable = false, length = 15)
    @Builder.Default
    private EstadoEnvio estado = EstadoEnvio.preparando;

    @Column(name = "courier", nullable = false, length = 50)
    private String courier;

    @Column(name = "fecha_estimada", nullable = false)
    private LocalDate fechaEstimada;

    public enum EstadoEnvio {
        preparando, en_ruta, entregado, devuelto
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Envio)) return false;
        Envio that = (Envio) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
}
