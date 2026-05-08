package cl.triskeledu.stock.model;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(name = "movimiento")
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Movimiento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sku", referencedColumnName = "sku", nullable = false)
    private ProductoProy producto;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "codigo_bodega", referencedColumnName = "codigo_bodega", nullable = false)
    private Bodega bodega;

    @Enumerated(EnumType.STRING)
    @Column(name = "tipo", nullable = false, length = 10)
    private TipoMovimiento tipo;

    @Column(name = "cantidad", nullable = false)
    private Integer cantidad;

    @CreatedDate
    @Column(name = "fecha", nullable = false, updatable = false)
    private LocalDateTime fecha;

    public enum TipoMovimiento {
        entrada, salida, ajuste
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Movimiento)) return false;
        Movimiento that = (Movimiento) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
}
