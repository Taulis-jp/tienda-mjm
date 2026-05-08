package cl.triskeledu.pedido.model;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(name = "estado_pedido")
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EstadoPedido {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "codigo_pedido", referencedColumnName = "codigo_pedido", nullable = false)
    private Pedido pedido;

    @Enumerated(EnumType.STRING)
    @Column(name = "estado", nullable = false, length = 20)
    private EstadoOrden estado;

    @Column(name = "observacion", nullable = true, length = 255)
    private String observacion;

    @CreatedDate
    @Column(name = "fecha", nullable = false, updatable = false)
    private LocalDateTime fecha;

    public enum EstadoOrden {
        pendiente, confirmado, en_despacho, entregado, cancelado
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof EstadoPedido)) return false;
        EstadoPedido that = (EstadoPedido) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
}
