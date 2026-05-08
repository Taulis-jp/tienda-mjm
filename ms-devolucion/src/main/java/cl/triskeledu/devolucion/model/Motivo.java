package cl.triskeledu.devolucion.model;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(
    name = "motivo",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_motivo_codigo_pedido", columnNames = "codigo_pedido")
    }
)
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Motivo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "codigo_pedido", referencedColumnName = "codigo_pedido", nullable = false, unique = true)
    private Devolucion devolucion;

    @Enumerated(EnumType.STRING)
    @Column(name = "tipo", nullable = false, length = 25)
    private TipoMotivo tipo;

    @Column(name = "descripcion", nullable = true, length = 255)
    private String descripcion;

    @CreatedDate
    @Column(name = "fecha", nullable = false, updatable = false)
    private LocalDateTime fecha;

    public enum TipoMotivo {
        talla_incorrecta, defecto, no_corresponde, arrepentimiento
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Motivo)) return false;
        Motivo that = (Motivo) o;
        return id != null && id.equals(that.id);
    }

    @Override
    public int hashCode() {
        return id != null ? id.hashCode() : 0;
    }
}
