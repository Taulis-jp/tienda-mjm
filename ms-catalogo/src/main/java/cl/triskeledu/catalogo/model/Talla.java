package cl.triskeledu.catalogo.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "talla")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Talla {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sku", referencedColumnName = "sku", nullable = false)
    private Producto producto;

    @Column(name = "nombre_talla", nullable = false, length = 10)
    private String nombreTalla;

    @Column(name = "disponible", nullable = false)
    @Builder.Default
    private Boolean disponible = true;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Talla)) return false;
        Talla that = (Talla) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
}
