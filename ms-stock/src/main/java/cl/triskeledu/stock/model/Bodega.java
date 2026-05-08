package cl.triskeledu.stock.model;

import jakarta.persistence.*;
import lombok.*;

import java.util.List;

@Entity
@Table(
    name = "bodega",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_bodega_codigo", columnNames = "codigo_bodega")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Bodega {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "codigo_bodega", nullable = false, length = 20, unique = true)
    private String codigoBodega;

    @Column(name = "nombre", nullable = false, length = 100)
    private String nombre;

    @Column(name = "ciudad", nullable = false, length = 100)
    private String ciudad;

    @Column(name = "activa", nullable = false)
    @Builder.Default
    private Boolean activa = true;

    @OneToMany(mappedBy = "bodega", fetch = FetchType.LAZY)
    private List<Inventario> inventarios;

    @OneToMany(mappedBy = "bodega", fetch = FetchType.LAZY)
    private List<Movimiento> movimientos;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Bodega)) return false;
        Bodega that = (Bodega) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
}
