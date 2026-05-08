package cl.triskeledu.catalogo.model;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(
    name = "proveedor_proy",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_proveedor_proy_rut", columnNames = "rut_proveedor")
    }
)
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProveedorProy {

    @Id
    @Column(name = "rut_proveedor", nullable = false, length = 12)
    private String rutProveedor;

    @Column(name = "nombre", nullable = false, length = 100)
    private String nombre;

    @CreatedDate
    @Column(name = "sincronizado", nullable = false, updatable = false)
    private LocalDateTime sincronizado;

    @OneToMany(mappedBy = "proveedor", fetch = FetchType.LAZY)
    private List<Producto> productos;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof ProveedorProy)) return false;
        ProveedorProy that = (ProveedorProy) o;
        return rutProveedor != null && rutProveedor.equals(that.rutProveedor);
    }

    @Override
    public int hashCode() {
        return rutProveedor != null ? rutProveedor.hashCode() : 0;
    }
}
