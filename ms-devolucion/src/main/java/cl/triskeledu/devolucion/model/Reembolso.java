package cl.triskeledu.devolucion.model;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(
    name = "reembolso",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_reembolso_codigo_pedido", columnNames = "codigo_pedido")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Reembolso {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "codigo_pedido", referencedColumnName = "codigo_pedido", nullable = false, unique = true)
    private Devolucion devolucion;

    @Column(name = "monto", nullable = false, precision = 10, scale = 2)
    private BigDecimal monto;

    @Enumerated(EnumType.STRING)
    @Column(name = "metodo", nullable = false, length = 30)
    private MetodoReembolso metodo;

    @Enumerated(EnumType.STRING)
    @Column(name = "estado", nullable = false, length = 15)
    @Builder.Default
    private EstadoReembolso estado = EstadoReembolso.pendiente;

    public enum MetodoReembolso {
        tarjeta_origen, transferencia, credito_tienda
    }

    public enum EstadoReembolso {
        pendiente, procesado, fallido
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Reembolso)) return false;
        Reembolso that = (Reembolso) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
}
