package cl.triskeledu.stock.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(
    name = "inventario",
    uniqueConstraints = {
        @UniqueConstraint(name = "uq_inventario_sku_bodega", columnNames = {"sku", "codigo_bodega"})
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Inventario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sku", referencedColumnName = "sku", nullable = false)
    private ProductoProy producto;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "codigo_bodega", referencedColumnName = "codigo_bodega", nullable = false)
    private Bodega bodega;

    @Column(name = "unidades", nullable = false)
    @Builder.Default
    private Integer unidades = 0;

    @Column(name = "reservadas", nullable = false)
    @Builder.Default
    private Integer reservadas = 0;

    @Transient
    public Integer getDisponiblesReales() {
        return unidades - reservadas;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Inventario)) return false;
        Inventario that = (Inventario) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
}
