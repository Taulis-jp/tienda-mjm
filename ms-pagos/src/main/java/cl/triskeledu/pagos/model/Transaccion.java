package cl.triskeledu.pagos.model;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(
    name = "transaccion",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_transaccion_codigo", columnNames = "codigo_transaccion")
    }
)
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Transaccion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "codigo_pedido", referencedColumnName = "codigo_pedido", nullable = false)
    private PedidoProy pedido;

    @Column(name = "codigo_transaccion", nullable = false, length = 100, unique = true)
    private String codigoTransaccion;

    @Enumerated(EnumType.STRING)
    @Column(name = "estado", nullable = false, length = 15)
    private EstadoTransaccion estado;

    @CreatedDate
    @Column(name = "fecha", nullable = false, updatable = false)
    private LocalDateTime fecha;

    public enum EstadoTransaccion {
        exitosa, fallida, timeout, reversada
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Transaccion)) return false;
        Transaccion that = (Transaccion) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
}
