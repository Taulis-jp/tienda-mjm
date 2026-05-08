package cl.triskeledu.ofertas.model;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(
    name = "producto_proy",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_producto_proy_sku", columnNames = "sku")
    }
)
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProductoProy {

    @Id
    @Column(name = "sku", nullable = false, length = 50)
    private String sku;

    @Column(name = "nombre", nullable = false, length = 100)
    private String nombre;

    @Column(name = "precio", nullable = false, precision = 10, scale = 2)
    private BigDecimal precio;

    @CreatedDate
    @Column(name = "sincronizado", nullable = false, updatable = false)
    private LocalDateTime sincronizado;

    @OneToMany(mappedBy = "producto", fetch = FetchType.LAZY)
    private List<Regla> reglas;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof ProductoProy)) return false;
        ProductoProy that = (ProductoProy) o;
        return sku != null && sku.equals(that.sku);
    }

    @Override
    public int hashCode() {
        return sku != null ? sku.hashCode() : 0;
    }
}
