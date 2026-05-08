package cl.triskeledu.envios.model;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(
    name = "pedido_proy",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_pedido_proy_codigo", columnNames = "codigo_pedido")
    }
)
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PedidoProy {

    @Id
    @Column(name = "codigo_pedido", nullable = false, length = 50)
    private String codigoPedido;

    @Column(name = "total", nullable = false, precision = 10, scale = 2)
    private BigDecimal total;

    @CreatedDate
    @Column(name = "sincronizado", nullable = false, updatable = false)
    private LocalDateTime sincronizado;

    @OneToOne(mappedBy = "pedido", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private Envio envio;

    @OneToMany(mappedBy = "pedido", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Seguimiento> seguimientos;

    @OneToOne(mappedBy = "pedido", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private DireccionEnvio direccionEnvio;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof PedidoProy)) return false;
        PedidoProy that = (PedidoProy) o;
        return codigoPedido != null && codigoPedido.equals(that.codigoPedido);
    }

    @Override
    public int hashCode() {
        return codigoPedido != null ? codigoPedido.hashCode() : 0;
    }
}
