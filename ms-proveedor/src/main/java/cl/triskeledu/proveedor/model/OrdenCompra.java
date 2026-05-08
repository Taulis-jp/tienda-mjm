package cl.triskeledu.proveedor.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "orden_compra")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrdenCompra {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "rut_proveedor", referencedColumnName = "rut_proveedor", nullable = false)
    private Proveedor proveedor;

    @Column(name = "sku_producto", nullable = false, length = 50)
    private String skuProducto;

    @Column(name = "cantidad", nullable = false)
    private Integer cantidad;

    @Enumerated(EnumType.STRING)
    @Column(name = "estado", nullable = false, length = 15)
    @Builder.Default
    private EstadoOrden estado = EstadoOrden.pendiente;

    public enum EstadoOrden {
        pendiente, confirmada, recibida, cancelada
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof OrdenCompra)) return false;
        OrdenCompra that = (OrdenCompra) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
}
